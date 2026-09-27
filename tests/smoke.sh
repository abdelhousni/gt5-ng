#!/bin/sh
# Smoke test for gt5: scan a generated directory tree under every
# available POSIX shell and check the HTML report.
#
# Usage: tests/smoke.sh [path/to/gt5]
#
# Part of gt5-ng. Licensed under the GNU General Public License version 2.

GT5=${1:-$(dirname "$0")/../gt5}
[ -f "$GT5" ] || { echo "gt5 not found: $GT5"; exit 2; }
GT5=$(cd "$(dirname "$GT5")" && pwd)/$(basename "$GT5")

WORK=$(mktemp -d) || exit 2
trap 'rm -rf "$WORK"' EXIT
trap 'exit 130' HUP INT TERM

#a fake "text browser" that copies the report to $OUT
mkdir "$WORK/bin"
cat > "$WORK/bin/browser" <<'EOT'
#!/bin/sh
cp "$1" "$OUT"
EOT
chmod +x "$WORK/bin/browser"

failures=0
fail() { echo "  FAIL: $*"; failures=$((failures+1)); }
pass() { echo "  ok:   $*"; }

#run gt5 with an isolated $HOME; stderr goes to $WORK/err
gt5() {
  rm -f "$WORK/out.html"
  HOME="$WORK/home" OUT="$WORK/out.html" GT5_BROWSER="$WORK/bin/browser" \
    $SHELL_CMD "$GT5" "$@" > "$WORK/log" 2> "$WORK/err"
}

#no shell errors such as "unexpected operator" or "not found"
check_stderr() {
  if grep -iE 'unexpected operator|not found|syntax error|bad substitution|run time error' \
      "$WORK/err" > /dev/null; then
    fail "$1: shell errors on stderr:"; sed 's/^/        /' "$WORK/err"
  fi
}

has() { grep -e "$1" "$WORK/out.html" > /dev/null 2>&1; }

run_suite() {
  rm -rf "${WORK:?}/home" "${WORK:?}/data"
  mkdir -p "$WORK/home" "$WORK/data/sub"
  dd if=/dev/zero of="$WORK/data/big" bs=1024 count=300 2> /dev/null
  dd if=/dev/zero of="$WORK/data/sub/small" bs=1024 count=40 2> /dev/null

  gt5 --version; check_stderr "--version"
  if grep '^gt5 v' "$WORK/log" > /dev/null; then pass "--version"; else fail "--version"; fi

  #first scan
  gt5 "$WORK/data"; check_stderr "first scan"
  if [ ! -s "$WORK/out.html" ]; then
    fail "first scan: no report written"
  elif has 'directory seems to be empty'; then
    fail "first scan: report says the directory is empty"
  elif has '\./big' && has '\./<a href="#[0-9]*">sub</a>/' && has '\./small'; then
    pass "first scan lists files and subdirectories"
  else
    fail "first scan: files missing from report"
  fi
  if has '(:/'; then fail "report header has an empty hostname"; else pass "hostname in header"; fi

  #second scan: diffs against the saved state
  dd if=/dev/zero of="$WORK/data/added" bs=1024 count=80 2> /dev/null
  gt5 "$WORK/data"; check_stderr "second scan"
  if has 'last check was on' && has '\./added .*>new<'; then
    pass "second scan shows changes since the first"
  else
    fail "second scan: no diff information"
  fi

  #--save-as with an absolute path
  (cd "$WORK/data" && gt5 --save-as "$WORK/saved.html"); check_stderr "--save-as"
  if [ -s "$WORK/saved.html" ] && grep '\./big' "$WORK/saved.html" > /dev/null; then
    pass "--save-as with an absolute path"
  else
    fail "--save-as with an absolute path"
  fi
  rm -f "$WORK/saved.html"
}

tested=0
for SHELL_CMD in sh dash bash "busybox sh" ksh mksh zsh; do
  command -v "${SHELL_CMD%% *}" > /dev/null 2>&1 || continue
  [ "$SHELL_CMD" = "busybox sh" ] && ! busybox sh -c : 2> /dev/null && continue
  [ "$SHELL_CMD" = zsh ] && SHELL_CMD="zsh --emulate sh"
  echo "== $SHELL_CMD"
  run_suite
  tested=$((tested+1))
done

echo
if [ "$failures" -eq 0 ]; then
  echo "PASS ($tested shells)"
else
  echo "FAIL: $failures check(s) failed"
  exit 1
fi
