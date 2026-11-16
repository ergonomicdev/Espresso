# Developer shortcuts. Works with plain `swift` commands too; this just picks a sane toolchain.
# Packaging and the Xcode project need full Xcode, so if the selected developer directory isn't
# an Xcode and /Applications/Xcode.app exists, use it for this invocation.
XCODE_DEV := /Applications/Xcode.app/Contents/Developer
ifeq ($(findstring Xcode,$(shell xcode-select -p 2>/dev/null)),)
ifneq ($(wildcard $(XCODE_DEV)),)
export DEVELOPER_DIR ?= $(XCODE_DEV)
endif
endif

.PHONY: help build run test icon project app dmg install clean

help:
	@echo "make build      build with SwiftPM"
	@echo "make run        run the app (menu bar only, no Dock icon)"
	@echo "make test       run unit tests"
	@echo "make app        build dist/Espresso.app (universal, Release)"
	@echo "make dmg        build dist/Espresso-<version>.dmg and .zip"
	@echo "make install    build and copy Espresso.app to /Applications"
	@echo "make icon       regenerate the app icon"
	@echo "make project    regenerate Espresso.xcodeproj (needs xcodegen)"
	@echo "make clean      remove build products"

build:
	swift build

run:
	swift run Espresso

test:
	swift test

icon:
	swift Tools/GenerateIcon.swift

project:
	xcodegen generate

app dmg:
	Tools/package-app.sh

install: app
	rm -rf /Applications/Espresso.app
	cp -R dist/Espresso.app /Applications/
	@echo "Installed /Applications/Espresso.app"

clean:
	rm -rf .build dist
