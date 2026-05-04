#!/bin/bash
# Reproduces the instacart-ios Carthage flow for RxSwift / RxRelay / RxCocoa:
#   - BUILD_LIBRARY_FOR_DISTRIBUTION = YES   (Carthage --use-xcframeworks default)
#   - MACH_O_TYPE = staticlib                (instacart-ios xcconfig override)
# Output goes to ./xcframeworks-source/{Scheme}.xcframework
set -euo pipefail

VERSION="${RX_VERSION:-6.10.2}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$HERE/.rx-build"
OUT="$HERE/xcframeworks-source"
SRC="$WORK/RxSwift-$VERSION"

rm -rf "$OUT"
mkdir -p "$OUT" "$WORK"

if [ ! -d "$SRC" ]; then
  echo "==> Downloading RxSwift $VERSION"
  curl -sL "https://github.com/ReactiveX/RxSwift/archive/refs/tags/$VERSION.tar.gz" \
    | tar -xz -C "$WORK"
fi

XCCONFIG="$(mktemp /tmp/rx-static.xcconfig.XXXXXX)"
trap 'rm -f "$XCCONFIG"' INT TERM HUP EXIT

cat > "$XCCONFIG" <<'EOF'
BUILD_LIBRARY_FOR_DISTRIBUTION = YES
MACH_O_TYPE = staticlib
DEBUG_INFORMATION_FORMAT = dwarf
GCC_GENERATE_DEBUGGING_SYMBOLS = NO
CLANG_ENABLE_CODE_COVERAGE = NO
SWIFT_SERIALIZE_DEBUGGING_OPTIONS = NO
OTHER_SWIFT_FLAGS = $(inherited) -Xfrontend -no-serialize-debugging-options
GCC_TREAT_WARNINGS_AS_ERRORS = NO
SWIFT_TREAT_WARNINGS_AS_ERRORS = NO
EOF

export XCODE_XCCONFIG_FILE="$XCCONFIG"

PROJECT="$SRC/Rx.xcodeproj"

archive() {
  local scheme=$1 destination=$2 archive_path=$3
  echo "==> Archiving $scheme for $destination"
  xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$scheme" \
    -configuration Release \
    -destination "$destination" \
    -archivePath "$archive_path" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
    >/dev/null
}

make_xcframework() {
  local scheme=$1
  local sim_archive="$WORK/$scheme-iphonesimulator.xcarchive"
  local dev_archive="$WORK/$scheme-iphoneos.xcarchive"

  archive "$scheme" "generic/platform=iOS Simulator" "$sim_archive"
  archive "$scheme" "generic/platform=iOS"           "$dev_archive"

  echo "==> Creating $scheme.xcframework"
  xcodebuild -create-xcframework \
    -framework "$sim_archive/Products/Library/Frameworks/$scheme.framework" \
    -framework "$dev_archive/Products/Library/Frameworks/$scheme.framework" \
    -output "$OUT/$scheme.xcframework" \
    >/dev/null
}

for scheme in RxSwift RxRelay RxCocoa; do
  make_xcframework "$scheme"
done

echo
echo "Done. Frameworks in $OUT:"
ls "$OUT"
echo
echo "Sanity check (RxCocoa MachO type):"
file "$OUT/RxCocoa.xcframework/ios-arm64/RxCocoa.framework/RxCocoa"
