#!/bin/sh
# Smoke test for gt5: scan generated directory trees under every
# available POSIX shell and check the HTML report, including hostile
# and unusual file and directory names.
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
#for the signal test: tell where the report is, then take a while
[ -z "$SLOW" ] || { dirname "$1" > "$SLOW"; sleep 2; }
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
has_text() { grep -F -e "$1" "$WORK/out.html" > /dev/null 2>&1; }
mkfile() { dd if=/dev/zero of="$1" bs=1024 count="$2" 2> /dev/null; }

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

  #--max-depth: nothing deeper than max-depth+1 in the report
  rm -rf "${WORK:?}/deep"; mkdir -p "$WORK/deep/a/b/c/d"
  mkfile "$WORK/deep/a/b/c/d/leaf" 20; mkfile "$WORK/deep/top" 20
  gt5 --max-depth 1 --no-diffs "$WORK/deep"; check_stderr "--max-depth"
  #depth 1 shows ./a/ and, one level below, ./b as a leaf (see BUGS in gt5.1)
  if has '\./top' && has '\./b *$' && ! has '\./c' && ! has '\./leaf' \
      && ! has '\./<a href="#[0-9]*">[bc]</a>/'; then
    pass "--max-depth limits the report"
  else
    fail "--max-depth does not limit the report"
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

#expect: status "$1", then gt5 arguments; checks the exit status only
expect_status() {
  want=$1; shift
  gt5 "$@"; got=$?
  if [ "$got" = "$want" ]; then pass "gt5 $* -> exit $want"
  else fail "gt5 $* -> exit $got, expected $want"; sed 's/^/        /' "$WORK/err"; fi
}

#option parsing: see docs/AUDIT.md, findings 5, 6 and 13
run_options() {
  rm -rf "${WORK:?}/home"; mkdir -p "$WORK/home"
  expect_status 0 --help
  expect_status 0 --cut-at 0.10 --version
  expect_status 0 --cut-at 30 --version
  expect_status 1 --cut-at 30.5
  expect_status 1 --cut-at 0.001
  expect_status 1 --cut-at abc
  expect_status 0 --max-lines 500 --version
  expect_status 1 --max-lines 0
  expect_status 1 --save-as "$WORK/no/such/dir/x"
  expect_status 1 --save-as "$WORK"
  expect_status 1 --diff-dir
  expect_status 2 --get-links
  expect_status 2 "$WORK/no/such/dir"
  if grep -q '^gt5: ' "$WORK/err" || [ -s "$WORK/log" ]; then
    fail "usage errors must print the help on stderr only"
  else
    pass "usage errors print the help on stderr"
  fi
}

#hostile or unusual names: see docs/AUDIT.md, findings 2, 3, 8, 9, 11
run_security() {
  rm -rf "${WORK:?}/home" "${WORK:?}/sec"
  mkdir -p "$WORK/home" "$WORK/sec"

  #a directory name that used to be executed as awk code
  evil="$WORK/sec/evil\"system(\"touch PWNED\")\""
  mkdir "$evil" && mkfile "$evil/x" 20
  gt5 "$evil"; check_stderr "awk injection"
  if [ -e "$evil/PWNED" ] || [ -e "$WORK/sec/PWNED" ]; then
    fail "directory name was executed as awk code"
  elif has '\./x' && has_text 'evil&quot;system(&quot;touch PWNED&quot;)&quot;'; then
    pass "directory name with quotes is data, not code"
  else
    fail "awk injection: report incomplete"
  fi

  #'%' used to be read as a printf format
  mkdir "$WORK/sec/p%sq" && mkfile "$WORK/sec/p%sq/y" 20
  gt5 "$WORK/sec/p%sq"; check_stderr "percent in path"
  if has '\./y' && has_text 'p%sq)'; then
    pass "'%' in the path"
  else
    fail "'%' in the path"
  fi

  #backslashes used to be interpreted by echo and awk
  mkdir "$WORK/sec/back\tslash" && mkfile "$WORK/sec/back\tslash/z" 20
  gt5 "$WORK/sec/back\tslash"; check_stderr "backslash in path"
  if has '\./z' && has_text 'back\tslash)'; then
    pass "backslash in the path"
  else
    fail "backslash in the path"
  fi

  #file names must be HTML-escaped, and file links URL-encoded
  mkdir "$WORK/sec/h"
  mkfile "$WORK/sec/h/<b>bold" 20; mkfile "$WORK/sec/h/a&b" 20
  mkfile "$WORK/sec/h/sp ace#1" 20
  gt5 --link-files "$WORK/sec/h"; check_stderr "HTML escaping"
  if has_text '<b>bold'; then
    fail "file name written into the report as raw HTML"
  elif has_text '&lt;b&gt;bold' && has_text 'a&amp;b'; then
    pass "file names are HTML-escaped"
  else
    fail "HTML escaping: names missing from report"
  fi
  if has_text '/sec/h/sp%20ace%231"'; then
    pass "--link-files links are URL-encoded"
  else
    fail "--link-files links are not URL-encoded"
  fi

  #paths with regex characters: diff a subdirectory against its parent
  sub="$WORK/sec/r/a+b (c)"
  mkdir -p "$sub" && mkfile "$sub/f" 20
  gt5 "$WORK/sec/r" && gt5 "$sub"; check_stderr "regex characters"
  if has 'last check was on' && has '\./f' && ! has '\./f .*>new<'; then
    pass "subdirectory with regex characters diffs against its parent"
  else
    fail "subdirectory with regex characters: no diff against its parent"
  fi

  #temporary files are removed when gt5 is killed with SIGHUP
  rm -f "$WORK/tmpdir"
  HOME="$WORK/home" OUT="$WORK/out.html" GT5_BROWSER="$WORK/bin/browser" \
    SLOW="$WORK/tmpdir" $SHELL_CMD "$GT5" "$WORK/sec/h" > /dev/null 2>&1 &
  pid=$!
  n=0; while [ ! -s "$WORK/tmpdir" ] && [ $n -lt 20 ]; do sleep 1; n=$((n+1)); done
  kill -HUP "$pid" 2> /dev/null; wait "$pid" 2> /dev/null
  if [ ! -s "$WORK/tmpdir" ]; then
    fail "signal test: browser was not started"
  elif [ -d "$(cat "$WORK/tmpdir")" ]; then
    fail "temporary directory left behind after SIGHUP"
    rm -rf "$(cat "$WORK/tmpdir")"
  else
    pass "temporary directory removed after SIGHUP"
  fi
}

#BSD/macOS userland: wrappers around the GNU tools that reject GNU-only
#usage (date -d, date -r FILE, stat -c, du --long-options) and log calls
make_bsd_shims() {
  mkdir -p "$WORK/bsd"
  real_date=$(command -v date); real_stat=$(command -v stat); real_du=$(command -v du)
  cat > "$WORK/bsd/date" <<EOT
#!/bin/sh
echo "date \$*" >> "$WORK/bsd.log"
for a do case "\$a" in -d*|--*) echo "date: illegal option" 1>&2; exit 1;; esac; done
if [ "\$1" = -r ]; then
  case "\$2" in ''|*[!0-9]*) echo "date: illegal time format" 1>&2; exit 1;; esac
  n=\$2; shift 2; exec "$real_date" -d "@\$n" "\$@"
fi
exec "$real_date" "\$@"
EOT
  cat > "$WORK/bsd/stat" <<EOT
#!/bin/sh
echo "stat \$*" >> "$WORK/bsd.log"
[ "\$1" = -f ] && [ "\$2" = %m ] && exec "$real_stat" -c %Y "\$3"
echo "stat: illegal option" 1>&2; exit 1
EOT
  cat > "$WORK/bsd/du" <<EOT
#!/bin/sh
echo "du \$*" >> "$WORK/bsd.log"
all=; depth=
for a do
  case "\$a" in
    --*) echo "du: illegal option" 1>&2; exit 1;;
    -d) depth=1;;
    -*a*) all=1;;
  esac
done
#BSD du: usage: du [-a | -s | -d depth]
[ "\$all\$depth" = 11 ] && { echo "du: -a and -d are mutually exclusive" 1>&2; exit 1; }
exec "$real_du" "\$@"
EOT
  chmod +x "$WORK/bsd/date" "$WORK/bsd/stat" "$WORK/bsd/du"
}

#see docs/AUDIT.md, finding 7
run_bsd() {
  rm -rf "${WORK:?}/home" "${WORK:?}/data" "$WORK/bsd.log"
  mkdir -p "$WORK/home" "$WORK/data/sub"
  mkfile "$WORK/data/big" 300; mkfile "$WORK/data/sub/small" 40
  PATH="$WORK/bsd:$PATH" gt5 "$WORK/data"; check_stderr "BSD first scan"
  mkfile "$WORK/data/added" 80
  PATH="$WORK/bsd:$PATH" gt5 "$WORK/data"; check_stderr "BSD second scan"
  year=$(date +%Y)
  if has "last check was on <font color=magenta>[^<]*$year" && has '\./added .*>new<' \
      && has '\./<a href="#[0-9]*">sub</a>/'; then
    pass "BSD-style date/stat/du: scan and diff with the last run's date"
  else
    fail "BSD-style date/stat/du: report or diff date wrong"
  fi
  if grep -q '^stat -f %m ' "$WORK/bsd.log" && grep -q '^date -r [0-9]' "$WORK/bsd.log" \
      && grep -q '^du -akx *$' "$WORK/bsd.log"; then
    pass "BSD fallbacks used (stat -f, date -r SECONDS, du without -d)"
  else
    fail "BSD fallbacks not used:"; sed 's/^/        /' "$WORK/bsd.log"
  fi
}

#the wrappers need GNU date/stat underneath; on BSD/macOS the real tools
#are tested directly
if date -d @0 > /dev/null 2>&1 && stat -c %Y / > /dev/null 2>&1; then
  make_bsd_shims; BSD_SHIMS=1
fi

tested=0
for SHELL_CMD in sh dash bash "busybox sh" ksh mksh zsh; do
  command -v "${SHELL_CMD%% *}" > /dev/null 2>&1 || continue
  [ "$SHELL_CMD" = "busybox sh" ] && ! busybox sh -c : 2> /dev/null && continue
  [ "$SHELL_CMD" = zsh ] && SHELL_CMD="zsh --emulate sh"
  echo "== $SHELL_CMD"
  run_suite
  run_security
  run_options
  [ -z "$BSD_SHIMS" ] || run_bsd
  tested=$((tested+1))
done

echo
if [ "$failures" -eq 0 ]; then
  echo "PASS ($tested shells, awk: $(basename "${GT5_AWK:-default}"))"
else
  echo "FAIL: $failures check(s) failed"
  exit 1
fi
