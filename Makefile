# Makefile for DropBasket
# Author: lalitaalaalitah
# Website: https://www.lalitaalaalitah.com
# GitHub Profile: https://github.com/lalitaalaalitah

VERSION = 1.0.0

.PHONY: all build app test install clean version help

all: app

build:
	swift build -c release

app:
	@chmod +x scripts/*.sh scripts/*.swift
	@./scripts/build_app.sh

test:
	swift test

install: app
	@./scripts/install.sh

clean:
	rm -rf .build build Resources/AppIcon.icns

version:
	@echo "DropBasket v$(VERSION) by lalitaalaalitah (https://www.lalitaalaalitah.com)"

help:
	@echo "DropBasket Makefile commands:"
	@echo "  make app      - Build release and package DropBasket.app bundle"
	@echo "  make install  - Install DropBasket.app to ~/Applications and dropbasket CLI to ~/.local/bin"
	@echo "  make test     - Run unit test suite"
	@echo "  make build    - Swift build in release mode"
	@echo "  make clean    - Remove build artifacts"

