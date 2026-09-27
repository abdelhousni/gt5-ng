# Audit of gt5 1.4.0

Audit of the unmodified upstream script (`gt5` at tag `upstream/1.4.0`),
done 2026-09-27 as the starting point for gt5-ng.

**Test environment:** Debian-based Linux, `/bin/sh` = dash, bash 5,
GNU coreutils 9.4 (`du`), mawk, ShellCheck 0.11.0 (`-s sh`). A fake browser
script captured the generated HTML.

Each finding is marked **Verified** (reproduced) or **Reading** (found by
reading the code, not reproduced).

## Summary

| # | Severity | Finding | Status |
|:-:|:--|:--|:--|
| 1 | Critical | Always shows "directory seems to be empty" on current GNU coreutils | Verified |
| 2 | High | Directory path is pasted into awk code → arbitrary command execution | Verified |
| 3 | High | `%` in the directory path crashes HTML generation | Verified |
| 4 | High | Bash-only syntax breaks under `/bin/sh` = dash (Debian/Ubuntu) | Verified |
| 5 | High | `--save-as` with an absolute path fails under dash | Verified |
| 6 | Medium | `--get-*` options call an undefined function | Verified |
| 7 | Medium | BSD/macOS `du` and `date` are not supported | Reading |
| 8 | Medium | File names are not HTML-escaped | Verified |
| 9 | Medium | Paths used as regexes when diffing subdirectories | Reading |
| 10 | Low | File names containing a newline are silently dropped | Verified |
| 11 | Low | Temp dir cleanup misses Ctrl-C / hang-up | Reading |
| 12 | Low | Relies on `which` and `echo -e`/`-n` | Verified |
| 13 | Low | Option validation quirks | Reading |

ShellCheck (`shellcheck -s sh gt5`) reports 60 findings: 13×SC2016,
11×SC2086, 7×SC3028, 6×SC3037, 5×SC2166, 4×SC2088, 4×SC2015, 3×SC2064,
2×SC3014, 2×SC2164, 1×SC3020, 1×SC2209, 1×SC2046. Most SC2016 notes are
intentional (awk programs in single quotes); the SC3xxx ones are the
real portability bugs below.

## Findings

### 1. Empty output on current GNU coreutils — Critical, Verified

Lines 263–265 detect the depth option by parsing `du --help`. Modern
coreutils lists it as `-d, --max-depth=N`, so the awk extracts `-d,` and
gt5 runs `du -akx -d,6`. `du` rejects that, its error goes to
`/dev/null`, and every run shows **"directory seems to be empty"**. This
is what downstream patches such as Arch's `handle_depth.patch` work
around. **gt5 1.4.0 is unusable as released on current Linux.**

Fix: use `-d N` (accepted by current GNU and BSD `du`) or probe with
`du -d 0 . >/dev/null 2>&1`, falling back to `--max-depth=N`.

### 2. Command execution through the directory path — High, Verified

Shell variables are spliced into awk program text instead of being
passed with `-v`. `$P` (hostname and `$PWD`) goes into the awk
program at line 340 on every run, and `$PWD` again at line 350 with
`--link-files`; `$DATE`, `$F2`, `$CUT`, `$GT5_CHARSET`/`$LANG` and the
colour settings are spliced the same way.

Reproduced: running `gt5` on a directory named
`evil"system("touch PWNED")"` created the file `PWNED`. Anyone who can
name a directory you later scan (an unpacked archive, a shared or
world-writable tree) can run commands as you — including root, if gt5 is
run with sudo.

Fix: pass every value with `awk -v name=value` (or `ENVIRON`) and never
build awk code from data.

### 3. `%` in the path crashes the report — High, Verified

The same spliced string is used as a `printf` format (line 340). A
directory such as `p%sq` makes awk abort with *"not enough arguments
passed to printf"*, leaving a truncated HTML file. Fix together with #2
by printing data with `printf "%s", value`.

### 4. Bash-only syntax under `/bin/sh` — High, Verified

The shebang is `#!/bin/sh`, but the script uses bashisms. On dash:

- `[ "$F1" == "$DDIR/" ]` (lines 192, 251) errors with *"unexpected
  operator"*; the test is always false.
- `which which &> /dev/null` (line 24) parses as `which which &` plus a
  separate redirect: it runs in the background, prints `/usr/bin/which`
  to the terminal, and the check never fails.
- `$HOSTNAME` is unset, so the report header reads `(:/path)`.
- `$RANDOM` is empty (temp-dir fallback name, space/tab markers).
- `$SECONDS` is unset, so timings are blank.
- `echo -e` / `echo -n` behave differently.

Fix: use `=`, `command -v`, `$(hostname)`/`uname -n`, `printf`, and run
ShellCheck in CI; or, if bash is preferred, say so in the shebang.

### 5. `--save-as /absolute/path` fails under dash — High, Verified

Because of the `==` error in #4, every `--save-as` path is treated as
relative and prefixed with `$PWD`, so an absolute path becomes
`$PWD//abs/path` and the write fails with *"Directory nonexistent"*. An
empty file is still left at the real path by the earlier `touch`.

### 6. `--get-awk`, `--get-links`, … are broken — Medium, Verified

They call `install_pkg`, which is not defined anywhere in the script
(*"install_pkg: not found"*). Execution then continues. Remove the
options (auto-installing packages is out of place in a script like this).

### 7. BSD/macOS not supported — Medium, Reading

- BSD `du` has no `--help`, so `DEPTH` becomes the bare number `6`,
  which `du` then treats as a path to scan.
- `date -r FILE` (line 257) means "seconds since epoch" on BSD, not "file
  modification time"; the "last check" date and elapsed time break.
  Portable alternative: store the timestamp inside the state file, or
  use `stat` with per-platform flags.

(vasi/gt5 worked around this by requiring GNU `gdu`/`gdate`.)

### 8. File names not HTML-escaped — Medium, Verified

A file named `<b>bold` is written into the report as raw HTML. In text
browsers this mostly garbles the display, but with `--link-files` a
crafted name can inject links/markup, and `~/.gt5.html` may later be
opened in a graphical browser. Escape `&`, `<`, `>`, `"` in names and
paths.

### 9. Paths treated as regular expressions — Medium, Reading

When diffing a subdirectory against a saved parent scan, `$CUT` is
turned into an awk regex with only `/` escaped (line 285), and the
first line's path is used in `sub(P, …)`. Paths containing `.` `+` `(`
`[` `*` etc. can mismatch, producing wrong or missing diffs. Use
`index()`/`substr()` for literal matching.

### 10. Newlines in file names — Low, Verified

A file whose name contains a newline disappears from the report (and
its size is misattributed). `du` has no NUL-separated output in POSIX;
acceptable to document, or handle with `du -0` where available.

### 11. Temp-dir cleanup on signals — Low, Reading

`trap … 0 15` covers exit and TERM only. dash does not run the EXIT
trap when killed by SIGINT/SIGHUP, so Ctrl-C can leave `/tmp/gt5.*`
behind. Trap `HUP INT TERM` too. The `mktemp`-less fallback
(`/tmp/gt5.$$.$RANDOM`) is predictable under dash, but `mkdir` fails
safely if it already exists; prefer requiring `mktemp` (available on every
current Linux, BSD and macOS system).

### 12. `which` and `echo` flags — Low, Verified

The dependency check relies on `which`, which is not POSIX and is
deprecated on Debian. Use `command -v`. Replace `echo -e`/`-n` with
`printf` (see #4).

### 13. Option validation quirks — Low, Reading

- `--cut-at` rejects `0.10` and `1.20` (last digit must be 1–9) but
  accepts `39.9`, although the help says 0.01–30.
- `--max-lines` refuses anything below 10000.
- `--save-as` creates the file before validating anything.
- Line 371 calls plain `awk` instead of `"$AWK"`.

## Progress

- 2026-09-27: #1, #4 and #5 fixed; the `which`/`echo` part of #12 fixed.
  `tests/smoke.sh` (`make check`) covers them.
- 2026-09-27: #2, #3, #8, #9 and #11 fixed, each with a test in
  `tests/smoke.sh`. The HTML colours are still written into the awk
  program, but they are constants set at the top of the script, not data.
- 2026-09-27: #6 and #13 fixed, #12 finished; `shellcheck -s sh gt5` is
  clean (SC2016 is disabled file-wide, since the awk programs are
  single-quoted on purpose). CI runs the tests under five shells.
  Open: #7 (BSD/macOS) and #10 (newlines in file names).

## Suggested order of work

1. **Make it run:** fix #1 (depth option) and #4 (POSIX `sh`), with a
   smoke test that scans a generated tree and checks the HTML.
2. **Make it safe:** fix #2/#3 (awk `-v`, `printf "%s"`), #8 (HTML
   escaping), #9 (literal matching), #11 (traps).
3. **Clean up:** #5, #6, #12, #13; get `shellcheck -s sh` clean.
4. **Portability:** #7 (BSD/macOS), with CI on Linux (dash, bash,
   busybox) and macOS.
