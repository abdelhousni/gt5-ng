# Notice

gt5-ng is derived from **gt5**, written by Thomas Sattler.

- Project page: https://gt5.sourceforge.net/
- SourceForge project: https://sourceforge.net/projects/gt5/

## Upstream source

The first import in this repository (commit `0fe6120`, tag `upstream/1.4.0`)
is the unmodified content of:

| | |
| :-- | :-- |
| File | `gt5-1.4.0.tar.gz` (released 2007-08-29) |
| URL | https://sourceforge.net/projects/gt5/files/gt5/gt5%2C%20version%201.4.0/ |
| SHA-256 | `785a2a71f77e29d2cf4bbd2c6f49f690d6fdcb5f53abd51aee393572fd7fa03e` |

## License

The upstream release says only "gt5 is released under GPL." (in `README`)
and ships the GNU General Public License version 2 text in `LICENSE`. It
names no version and says nothing about "any later version".

That is ambiguous. GPLv2 section 9 says that if a program names no version,
the recipient may choose any version ever published. On the other hand, the
shipped `LICENSE` is version 2, which suggests the author meant that.
Debian treats gt5 as `GPL-2+`, and the headers Jari Aalto added in 2008
(see below) also say "version 2 of the License, or (at your option) any
later version". Those headers are Aalto's wording, not Thomas Sattler's.

gt5-ng therefore labels itself **`GPL-2.0-only`**. This is a deliberately
conservative choice, not something the upstream text requires. It is safe
for everyone downstream, and relaxing it later to `GPL-2.0-or-later` is
easy once the original author confirms, whereas tightening it later would
not be. All modifications in this repository are released under the same
license.

As GPLv2 section 2(a) requires, files modified in this fork carry a notice
stating that they were changed and when. The original copyright belongs to
Thomas Sattler; contributors hold copyright only in their own changes.

## Related work: Jari Aalto's branch (2008-2011)

gt5-ng starts from the 1.4.0 release, but it is not the first fork. Jari
Aalto, a Debian maintainer, carried gt5 forward from 2008 to 2011 in a
Bazaar branch at https://launchpad.net/gt5 (listed as the source in
Debian's `debian/copyright`). Its last snapshot, version `1.4.0.3`, is
shipped by Debian and Ubuntu as `1.5.0~20111220+bzr29`
(sha256 of `gt5_1.5.0~20111220+bzr29.orig.tar.gz`:
`169b8d40881045c9f4402a12d6994cdfd0db87bf440a61e774b6f88dad68b2b6`).

It has patches from Stéphane Rosi and options of its own (`--debug`,
`--exclude`, `--megabytes`), and it uses bash-only features (`#!/bin/bash`,
`RANDOM`, `local`), where gt5-ng works toward plain POSIX `sh`. gt5-ng has
not copied code from that branch. Anything taken from it later will be
recorded in `CHANGELOG.md` with its origin.

Debian's package of that snapshot has had a different maintainer since
2021 (Arthur Diniz). Fedora packages 1.4.0, and Gentoo lists gt5 as
needing a maintainer.
