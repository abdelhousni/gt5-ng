# Changelog

All notable changes to gt5-ng are recorded here. The history of the
original gt5 up to 1.4.0 is in [`Changelog`](Changelog), kept as released.

## [Unreleased]

### Changed
- gt5-ng is versioned separately from the original gt5, using semantic
  versioning; the first release is 2.0.0 (see `docs/RELEASING.md`).
  `gt5 --version` prints e.g. `gt5 v2.0.0 (gt5-ng)`.
- Errors go to stderr, prefixed with `gt5:`, with exit status 1; usage
  errors print the help on stderr with exit status 2. New `-h`/`--help`
  prints the help on stdout and exits 0.
- `--cut-at` accepts any decimal number from 0.01 to 30 (1.4.0 rejected
  e.g. `0.10` and accepted `39.9`).
- `--max-lines` accepts any value from 1 (1.4.0 required at least 10000).
- `--save-as` checks that the file can be written up front, but no longer
  creates it until the report is ready. `--diff-dir`, `--save-as` and
  `--save-du-as` report a missing argument instead of misbehaving.

### Fixed (portability)
- BSD and macOS: the time of the last run (the "last check was on …" line
  and the time since) used GNU `date -r FILE`, which BSD/macOS `date`
  reads as a number of seconds. gt5 now gets the file time from `stat`
  (GNU/busybox `-c %Y`, BSD/macOS `-f %m`) and formats it with
  `date -d @N` or `date -r N`.
- BSD and macOS: every report was empty, because BSD/macOS `du` refuses
  `-a` together with `-d`. gt5 now probes that exact combination and,
  where it is refused, runs `du` without a depth limit and drops the
  deeper entries itself.
- `make install` no longer sets owner `root:root`, which fails on
  BSD/macOS (root's group is `wheel`) and in unprivileged packaging
  builds; the man page and docs are installed mode 644 instead of 755.

### Removed
- The `--get-awk`, `--get-gawk`, `--get-links`, `--get-links2` and
  `--get-elinks` options. They called a function that did not exist in
  1.4.0; install the tools with your package manager instead.

### Security
- A crafted directory name could run arbitrary commands: gt5 pasted the
  directory path (and the date, charset and other values) into the awk
  program text. All such values are now passed through the environment
  (`ENVIRON`) and never become awk code. The same change stops `%` in a
  path from crashing report generation, and stops backslashes in paths
  from being mangled.
- File and directory names are HTML-escaped in the report, and
  `--link-files` links are URL-encoded.
- Paths are matched literally instead of as regular expressions, so
  diffing a subdirectory whose path contains `.`, `+`, `(` etc. against a
  saved scan of its parent works. The names of existing state files in
  `~/.gt5-diffs` are unchanged.
- The temporary directory is also removed when gt5 is interrupted or
  hung up (SIGINT, SIGHUP), not only on exit and SIGTERM.

### Fixed
- gt5 no longer reports every directory as empty on current GNU coreutils:
  the `du` depth option is now detected by probing `du -d 0` (falling back
  to `--max-depth`) instead of parsing `du --help`, which produced the
  invalid option `-d,N`.
- gt5 runs under any POSIX `sh`, such as dash (`/bin/sh` on Debian and
  Ubuntu): `==` in tests replaced by `=`, `which` and `&>` replaced by
  `command -v`, `echo -e`/`-n` replaced by `printf`, and the bash-only
  `$HOSTNAME`, `$RANDOM` and `$SECONDS` given portable fallbacks. This also
  fixes `--save-as` with an absolute path and the empty hostname in the
  report header under dash.

- `--help` and `--version` no longer fail when no text browser is
  installed.

### Added
- `README.md`, `NOTICE.md` and this changelog, identifying the project as an
  unofficial fork of gt5 by Thomas Sattler, recording the upstream source
  and stating the license (GPL-2.0-only).
- `docs/AUDIT.md`: audit of the upstream 1.4.0 script (bugs, security,
  portability, ShellCheck) and the planned order of fixes.
- `tests/smoke.sh` and `make check`: scans a generated directory tree under
  every available POSIX shell and checks the report, diffs and `--save-as`,
  plus hostile and unusual names (quotes, `%`, backslashes, HTML, regex
  characters), cleanup after SIGHUP, and option parsing.
- `make lint` (ShellCheck; `gt5` is now clean with `-s sh`) and a GitHub
  Actions workflow: `make lint`, plus `make check` on Linux (sh, dash,
  bash, busybox sh, ksh, zsh; with mawk, BSD awk and busybox awk) and on
  macOS.
- Release tooling: `scripts/release.sh` (release commit and `vX.Y.Z`
  tag), `make check-version`, `make dist`, and a GitHub Actions workflow
  that publishes a release with a tarball and checksum when a tag is
  pushed.
- The smoke test emulates BSD `date`, `stat` and `du` on Linux, so the
  BSD code paths are also tested there.

## upstream/1.4.0 — imported 2026-09-27

- Unmodified import of gt5 1.4.0 (2007-08-29) from SourceForge.
