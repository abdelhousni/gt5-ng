#!/bin/sh
# Make a gt5-ng release commit and tag, locally. Nothing is pushed.
#
# Usage: scripts/release.sh X.Y.Z
#
#  1. checks: clean work tree, valid and new version, "## [Unreleased]"
#     section in CHANGELOG.md with content
#  2. sets version=X.Y.Z in gt5, the man page's .TH line (version and
#     month), and renames "## [Unreleased]" to "## [X.Y.Z] - YYYY-MM-DD"
#  3. runs make lint (if ShellCheck is installed) and make check
#  4. commits "Release X.Y.Z" and creates the annotated tag vX.Y.Z
#  5. commits "Start X.Y.(Z+1)-dev" with a fresh "## [Unreleased]" section
#
# Then push both commits and the tag:
#   git push origin HEAD && git push origin vX.Y.Z
# Pushing the tag runs .github/workflows/release.yml, which publishes the
# GitHub release.
#
# Part of gt5-ng. Licensed under the GNU General Public License version 2.

set -e
cd "$(dirname "$0")/.."
die() { echo "release: $*" 1>&2; exit 1; }

new=$1
case "$new" in
  ''|*[!0-9.]*|.*|*.|*..*) die "usage: scripts/release.sh X.Y.Z";;
  *.*.*.*) die "usage: scripts/release.sh X.Y.Z";;
  *.*.*) ;;
  *) die "usage: scripts/release.sh X.Y.Z";;
esac

[ -z "$(git status --porcelain)" ] || die "work tree is not clean"
git rev-parse -q --verify "refs/tags/v$new" > /dev/null && die "tag v$new already exists"
grep -q '^## \[Unreleased\]$' CHANGELOG.md || die "CHANGELOG.md has no [Unreleased] section"
#the [Unreleased] section must not be empty
awk '/^## \[Unreleased\]$/ { on = 1; next } /^## / { on = 0 } on && /[^ ]/ { n++ }
     END { exit !n }' CHANGELOG.md || die "the [Unreleased] section in CHANGELOG.md is empty"

today=$(date +%Y-%m-%d)
month=$(LC_ALL=C date +"%B %Y")

#portable in-place edit: sed into a temp file, then replace
edit() { file=$1; shift; sed "$@" "$file" > "$file.tmp" && cat "$file.tmp" > "$file" && rm -f "$file.tmp"; }

set_version() {
  edit gt5 -e "s/^version=.*/version=$1/"
  edit gt5.1 -e "s/^\\.TH gt5 1 \"[^\"]*\" \"gt5 v[^\"]*\"\$/.TH gt5 1 \"$month\" \"gt5 v$1\"/"
}

echo "== releasing $new"
set_version "$new"
edit CHANGELOG.md -e "s/^## \\[Unreleased\\]\$/## [$new] - $today/"
make check-version
if command -v shellcheck > /dev/null 2>&1; then make lint; else echo "(shellcheck not installed, skipping make lint)"; fi
make check
git commit -q -a -m "Release $new"
git tag -a "v$new" -m "gt5-ng $new"
echo "== tagged v$new"

#next development version
next=$(echo "$new" | awk -F. '{ printf "%d.%d.%d", $1, $2, $3+1 }')-dev
set_version "$next"
edit CHANGELOG.md -e "s/^## \\[$new\\] - $today\$/## [Unreleased]\\
\\
## [$new] - $today/"
make check-version
git commit -q -a -m "Start $next"
echo "== now at $next"
echo
echo "Push with:  git push origin HEAD && git push origin v$new"
