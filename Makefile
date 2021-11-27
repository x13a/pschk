NAME        := pschk

prefix      ?= /usr/local
exec_prefix ?= $(prefix)
bindir      ?= $(exec_prefix)/bin

bindestdir  := $(DESTDIR)$(bindir)
targetdir   := ./.build

all: build

build:
	swift build --configuration release

installdirs:
	install -d $(bindestdir)/

install: installdirs
	install $(targetdir)/release/$(NAME) $(bindestdir)/

uninstall:
	rm -f $(bindestdir)/$(NAME)

test:
	swift test

clean:
	rm -rf $(targetdir)/
