# Original gt5 by Thomas Sattler, https://gt5.sourceforge.net/
# Modified by abdel.h for gt5-ng, 2026-09-27: added the 'check' and 'lint'
# targets; version read from gt5; dist, check-version; 2026-09-30: portable install (no root:root owner, which fails
# on BSD/macOS where root's group is wheel; man page and docs mode 644).
# Licensed under the GNU General Public License version 2.

TARGET  = gt5
VERSION := $(shell sed -n 's/^version=//p' $(TARGET))
PREFIX  ?= /usr/local
MAN     ?= $(PREFIX)/share/man/man1
SHARE   ?= $(PREFIX)/share/$(TARGET)-$(VERSION)

.PHONY: build check check-version dist lint install install_doc uninstall

build:
	@echo nothing to build, gt5 is a shell-script
	@echo run 'make [un]install to [un]install'

check: check-version
	sh tests/smoke.sh ./$(TARGET)

check-version:
	sh scripts/check-version.sh

#source tarball of the committed tree (HEAD), e.g. gt5-ng-2.0.0.tar.gz
dist:
	git archive --format=tar --prefix=gt5-ng-$(VERSION)/ HEAD | gzip -n > gt5-ng-$(VERSION).tar.gz
	@echo gt5-ng-$(VERSION).tar.gz

lint:
	shellcheck -s sh $(TARGET) tests/smoke.sh scripts/*.sh

install:
	install -m 755 -d $(DESTDIR)$(MAN)
	install -m 755 -d $(DESTDIR)$(PREFIX)/bin
	install -m 644 $(TARGET).1 $(DESTDIR)$(MAN)
	install -m 755 $(TARGET) $(DESTDIR)$(PREFIX)/bin

install_doc:
	install -m 755 -d $(DESTDIR)$(SHARE)
	install -m 644 README LICENSE Changelog $(DESTDIR)$(SHARE)

uninstall:
	rm -rf $(DESTDIR)$(PREFIX)/bin/$(TARGET)
	rm -rf $(DESTDIR)$(MAN)/$(TARGET).1
	rm -rf $(DESTDIR)$(SHARE)

