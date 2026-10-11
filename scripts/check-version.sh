#!/bin/sh
# Check that the version is consistent across gt5-ng's files.
#
#  - gt5:          version=X.Y.Z or X.Y.Z-dev (the single source of truth)
#  - gt5.1:        .TH line says "gt5 vVERSION"
#  - CHANGELOG.md: a release (no "-dev") has a "## [X.Y.Z] - YYYY-MM-DD"
#                  section; "-dev" versions have an "## [Unreleased]" section
#  - git:          when HEAD carries a vX.Y.Z tag, it matches the version
#                  committed in HEAD
#
# Part of gt5-ng. Licensed under the GNU General Public License version 2.

cd "$(dirname "$0")/.." || exit 2
status=0
fail() { echo "check-version: $*" 1>&2; status=1; }

version=$(sed -n 's/^version=//p' gt5)
case "$version" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) fail "gt5: no valid version= line (found \"$version\")"; exit 1;;
esac
case "$version" in
  *[!0-9.]*-dev|*-dev*-dev) fail "gt5: bad version \"$version\"";;
  *-dev) release=;;
  *[!0-9.]*) fail "gt5: bad version \"$version\", use X.Y.Z or X.Y.Z-dev";;
  *) release=$version;;
esac

grep -q "^\.TH gt5 1 \"[^\"]*\" \"gt5 v$version\"\$" gt5.1 ||
  fail "gt5.1: .TH line does not say \"gt5 v$version\""

if [ "$release" ]; then
  grep -q "^## \[$release\] - [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\$" CHANGELOG.md ||
    fail "CHANGELOG.md: no \"## [$release] - YYYY-MM-DD\" section"
else
  grep -q '^## \[Unreleased\]$' CHANGELOG.md ||
    fail "CHANGELOG.md: no \"## [Unreleased]\" section for $version"
fi

if command -v git > /dev/null 2>&1 && git rev-parse --git-dir > /dev/null 2>&1; then
  #compare with the committed gt5, not the work tree (which may already
  #carry the next -dev version)
  head_version=$(git show HEAD:gt5 2> /dev/null | sed -n 's/^version=//p')
  for tag in $(git tag --points-at HEAD 'v*' 2> /dev/null); do
    [ "$tag" = "v$head_version" ] || fail "tag $tag on HEAD, but gt5 in HEAD says $head_version"
  done
fi

[ "$status" -eq 0 ] && echo "version $version: consistent"
exit "$status"
