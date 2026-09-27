# gt5-ng

An unofficial, community-maintained fork of **gt5 1.4.0** — "where has my
diskspace gone?". gt5 is a shell script that shows the disk space used by
files and directories as a browsable HTML tree, and what has changed since
it last ran.

- **Original project:** https://gt5.sourceforge.net/
- **Original author:** Thomas Sattler
- **License:** GNU General Public License, version 2 only (`GPL-2.0-only`) — see [`LICENSE`](LICENSE)

This fork is not affiliated with or endorsed by the original author.
It contains modifications made from 2026 onward; see
[`CHANGELOG.md`](CHANGELOG.md) for what changed and [`NOTICE.md`](NOTICE.md)
for provenance.

## Status

The repository currently holds the unmodified upstream 1.4.0 release
(git tag `upstream/1.4.0`). The upstream documentation is kept as released:
[`README`](README), [`INSTALL`](INSTALL), [`Changelog`](Changelog) and the
man page [`gt5.1`](gt5.1).

## Install

```sh
sudo make install        # installs gt5 and its man page under /usr/local
sudo make uninstall
```

`gt5` is a single shell script, so you can also copy it anywhere on your `PATH`.

## Usage

```sh
gt5 [options] [directory]
man gt5
```
