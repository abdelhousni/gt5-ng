# Changelog

All notable changes to gt5-ng are recorded here. The history of the
original gt5 up to 1.4.0 is in [`Changelog`](Changelog), kept as released.

## [Unreleased]

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

### Added
- `README.md`, `NOTICE.md` and this changelog, identifying the project as an
  unofficial fork of gt5 by Thomas Sattler, recording the upstream source
  and stating the license (GPL-2.0-only).
- `docs/AUDIT.md`: audit of the upstream 1.4.0 script (bugs, security,
  portability, ShellCheck) and the planned order of fixes.
- `tests/smoke.sh` and `make check`: scans a generated directory tree under
  every available POSIX shell and checks the report, diffs and `--save-as`.

## upstream/1.4.0 — imported 2026-09-27

- Unmodified import of gt5 1.4.0 (2007-08-29) from SourceForge.
