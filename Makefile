NAME        := pschk

prefix      ?= /usr/local
exec_prefix ?= $(prefix)
sbindir     ?= $(exec_prefix)/sbin

sbindestdir := $(DESTDIR)$(sbindir)
targetdir   := ./.build

all: build

build:
	swift build --configuration release

installdirs:
	install -d $(sbindestdir)/

install: installdirs
	install $(targetdir)/release/$(NAME) $(sbindestdir)/

uninstall:
	rm -f $(sbindestdir)/$(NAME)

test:
	swift test

clean:
	rm -rf $(targetdir)/
