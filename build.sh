#!/bin/zsh
set -e
ROOT="${0:A:h}"
# البناء في مجلد مؤقت: مزامنة iCloud لسطح المكتب تضيف سمات تكسر التوقيع
T=$(mktemp -d)
cp -R "$ROOT/src" "$T/src"
cd "$T" && mkdir -p out
APP="out/الملقّن العربي.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# الأيقونة
swiftc -O src/icon.swift -o out/mkicon
./out/mkicon out/icon1024.png
mkdir -p out/AppIcon.iconset
for s in 16 32 128 256 512; do
  sips -z $s $s out/icon1024.png --out out/AppIcon.iconset/icon_${s}x${s}.png >/dev/null
  d=$((s*2)); sips -z $d $d out/icon1024.png --out out/AppIcon.iconset/icon_${s}x${s}@2x.png >/dev/null
done
iconutil -c icns out/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"

# الملف التنفيذي لمعالجات أبل وإنتل
swiftc -O -target arm64-apple-macos12 src/main.swift -o out/m-arm64
swiftc -O -target x86_64-apple-macos12 src/main.swift -o out/m-x86_64
lipo -create out/m-arm64 out/m-x86_64 -output "$APP/Contents/MacOS/Mulaqqin"

cp src/index.html "$APP/Contents/Resources/index.html"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>الملقّن العربي</string>
  <key>CFBundleDisplayName</key><string>الملقّن العربي</string>
  <key>CFBundleIdentifier</key><string>com.yahya.mulaqqin</string>
  <key>CFBundleExecutable</key><string>Mulaqqin</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleDevelopmentRegion</key><string>ar</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.video</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>أداة مجانية من يحيى</string>
</dict></plist>
PLIST

codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP" && echo "SIGN OK"
lipo -info "$APP/Contents/MacOS/Mulaqqin"
(cd out && ditto -c -k --sequesterRsrc --keepParent "الملقّن العربي.app" "الملقّن-العربي.zip")
rm -rf "$ROOT/out" && mkdir -p "$ROOT/out"
cp "out/الملقّن-العربي.zip" "$ROOT/out/"
(cd "$ROOT/out" && ditto -x -k "الملقّن-العربي.zip" .)
rm -rf "$T"
ls -la "$ROOT/out"
