#!/bin/bash
# Builds a universal, ad-hoc-signed Release Espresso.app and packages it for distribution.
# Output (in ./dist): Espresso.app, Espresso-<version>.zip, Espresso-<version>.dmg
# Usage: Tools/package-app.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# Full Xcode is required; prefer it if the selected developer dir is Command Line Tools.
if [[ "$(xcode-select -p)" != *Xcode* && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

DERIVED="$(mktemp -d)"
trap 'rm -rf "$DERIVED"' EXIT
rm -rf dist && mkdir dist

xcodebuild -project Espresso.xcodeproj -scheme Espresso -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath "$DERIVED" \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual CODE_SIGNING_REQUIRED=NO \
  build | tail -3

cp -R "$DERIVED/Build/Products/Release/Espresso.app" dist/
codesign --force --deep --sign - dist/Espresso.app

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' dist/Espresso.app/Contents/Info.plist)"
ditto -c -k --keepParent dist/Espresso.app "dist/Espresso-$VERSION.zip"

STAGE="$(mktemp -d)"
cp -R dist/Espresso.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Espresso" -srcfolder "$STAGE" -ov -format UDZO "dist/Espresso-$VERSION.dmg" >/dev/null
rm -rf "$STAGE"

echo "Built version $VERSION:"
ls -1 dist
