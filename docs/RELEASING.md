# Versions and releases

## Version numbers

gt5-ng uses [semantic versioning](https://semver.org/): `MAJOR.MINOR.PATCH`.

- **MAJOR**: incompatible changes, such as removed or renamed options,
  changed exit statuses, or a changed state-file format in `~/.gt5-diffs`.
- **MINOR**: new, backwards-compatible features, such as new options.
- **PATCH**: bug and security fixes only.

The first gt5-ng release is **2.0.0**. It follows the original gt5 1.4.0
(2007) with a major bump, because gt5-ng removed options and changed exit
statuses. It also stays above Debian's `1.5.0~20111220+bzr29` package, an
unreleased upstream snapshot, so distributions can upgrade cleanly.

Between releases the version is `X.Y.Z-dev`, the next planned patch
release. A build from an untagged commit therefore never claims to be a
release.

## Where the version lives

- `gt5`: the `version=` line is the single source of truth. `gt5 --version`
  prints it.
- `Makefile`: reads it from `gt5`.
- `gt5.1`: the `.TH` line repeats it.
- `CHANGELOG.md`: `## [Unreleased]` during development,
  `## [X.Y.Z] - YYYY-MM-DD` for each release.

`make check-version` (part of `make check`) fails if these disagree, or if
a `vX.Y.Z` tag on `HEAD` does not match the committed version.

## Tags

- `vX.Y.Z`: gt5-ng releases. These are annotated tags, created by
  `scripts/release.sh`.
- `upstream/X.Y.Z`: unmodified releases of the original gt5, such as
  `upstream/1.4.0`.

Release tags are never moved or deleted. If a release is broken, a new
patch release replaces it.

## Making a release

From an up-to-date `main` with a clean work tree:

```sh
scripts/release.sh 2.0.0
git push origin HEAD && git push origin v2.0.0
```

`scripts/release.sh`:

1. checks that the work tree is clean, the tag is new, and the
   `[Unreleased]` changelog section is not empty;
2. sets the version in `gt5` and `gt5.1` (with the current month), and
   renames `[Unreleased]` to `[2.0.0] - <today>`;
3. runs `make lint` (if ShellCheck is installed) and `make check`;
4. commits `Release 2.0.0` and creates the annotated tag `v2.0.0`;
5. commits `Start 2.0.1-dev` with a new, empty `[Unreleased]` section.

Pushing the tag runs `.github/workflows/release.yml`. It checks that the tag
matches the version, runs the tests, builds `gt5-ng-2.0.0.tar.gz` (with
`make dist`, which runs `git archive`) and its SHA-256 checksum, and
publishes a GitHub release. The release notes are that version's section
of `CHANGELOG.md`.

For a minor or major release, pass that version, for example
`scripts/release.sh 2.1.0`. The next development version is always the
following patch release (`2.1.1-dev`). Raise it by hand in `gt5`, `gt5.1`
and the changelog if the next release will be a minor or major one.
