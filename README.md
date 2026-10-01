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

The unmodified upstream 1.4.0 release is tagged `upstream/1.4.0`. Since
then gt5-ng has fixed gt5 on current Linux systems, closed a command
execution hole and cleaned up option handling (see the changelog). The
upstream [`README`](README), [`INSTALL`](INSTALL) and
[`Changelog`](Changelog) are kept as released; the man page
[`gt5.1`](gt5.1) is updated for the changed options.

## Install

```sh
sudo make install        # installs gt5 and its man page under /usr/local
sudo make uninstall
```

`gt5` is a single shell script, so you can also copy it anywhere on your `PATH`.

## Development

```sh
make check   # smoke test under every installed POSIX shell
make lint    # ShellCheck
```

See [`docs/AUDIT.md`](docs/AUDIT.md) for known issues and progress, and
[`docs/RELEASING.md`](docs/RELEASING.md) for version numbers and releases.

## Usage

```sh
gt5 [options] [directory]
man gt5
```
