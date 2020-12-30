prefix ?= /usr/local
bindir = $(prefix)/bin
appname = things-url-generator

all: bootstrap

## build: launch build
build:
	swift build -c release --disable-sandbox

## install: install the application
install: build
	install ".build/release/$(appname)" "$(bindir)"

## uninstall: remove application
uninstall:
	rm -rf "$(bindir)/$(appname)"

## clean: clean build artifacts
clean:
	rm -rf .build

## bootstrap: Bootstrap project dependencies for development
bootstrap: hook
	mint bootstrap

## project: Generate xcproject file
project:
	swift package generate-xcodeproj

## fmt: Launch swift files code formatter
fmt:
	mint run swiftformat swiftformat Sources

## help: Prints help message
help:
	@echo "Usage: \n"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

.PHONY: build install uninstall clean help bootstrap test fmt
