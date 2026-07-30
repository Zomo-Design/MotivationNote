#!/bin/zsh
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
app_dir="$project_dir/dist/激励便签.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"

cd "$project_dir"
swift build -c release

rm -rf "$app_dir"
mkdir -p "$macos_dir"
cp \
  "$project_dir/.build/release/MotivationNote" \
  "$macos_dir/MotivationNote"

plutil -create xml1 "$contents_dir/Info.plist"
plutil -insert CFBundleName \
  -string "激励便签" \
  "$contents_dir/Info.plist"
plutil -insert CFBundleDisplayName \
  -string "激励便签" \
  "$contents_dir/Info.plist"
plutil -insert CFBundleIdentifier \
  -string "local.codex.MotivationNote" \
  "$contents_dir/Info.plist"
plutil -insert CFBundleExecutable \
  -string "MotivationNote" \
  "$contents_dir/Info.plist"
plutil -insert CFBundlePackageType \
  -string "APPL" \
  "$contents_dir/Info.plist"
plutil -insert CFBundleShortVersionString \
  -string "1.0.0" \
  "$contents_dir/Info.plist"
plutil -insert CFBundleVersion \
  -string "1" \
  "$contents_dir/Info.plist"
plutil -insert LSMinimumSystemVersion \
  -string "14.0" \
  "$contents_dir/Info.plist"
plutil -insert NSHighResolutionCapable \
  -bool true \
  "$contents_dir/Info.plist"

codesign --force --deep --sign - "$app_dir"
echo "$app_dir"
