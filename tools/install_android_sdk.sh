#!/usr/bin/env bash
# Install SDK packages needed by the Godot 4.6.3 prebuilt APK template.
# Installation accepts the Android SDK licenses required for these packages.
set -euo pipefail
ENIGMA_SDK_DIR="${ANDROID_HOME:-/workspace/.tools/android-sdk}"
ENIGMA_SDK_CACHE="${ENIGMA_SDK_CACHE:-/workspace/.tools/android-downloads}"
export ANDROID_USER_HOME="${ANDROID_USER_HOME:-/workspace/.local/android}"
mkdir -p "$ENIGMA_SDK_DIR" "$ENIGMA_SDK_CACHE" "$ANDROID_USER_HOME"
ENIGMA_TOOLS_ARCHIVE=commandlinetools-linux-13114758_latest.zip
ENIGMA_SDK_MANAGER="$ENIGMA_SDK_DIR/cmdline-tools/version19/cmdline-tools/bin/sdkmanager"
if [[ ! -x "$ENIGMA_SDK_MANAGER" ]]; then
  curl --fail --location --retry 3 --silent --show-error https://dl.google.com/android/repository/repository2-3.xml -o "$ENIGMA_SDK_CACHE/repository.xml"
  curl --fail --location --retry 3 --silent --show-error "https://dl.google.com/android/repository/$ENIGMA_TOOLS_ARCHIVE" -o "$ENIGMA_SDK_CACHE/$ENIGMA_TOOLS_ARCHIVE"
  python3 - "$ENIGMA_SDK_CACHE/repository.xml" "$ENIGMA_SDK_CACHE/$ENIGMA_TOOLS_ARCHIVE" <<'PY'
import hashlib, pathlib, sys, xml.etree.ElementTree as ET
archive=pathlib.Path(sys.argv[2])
root=ET.parse(sys.argv[1]).getroot()
for package in root.findall('remotePackage'):
    if package.attrib.get('path') != 'cmdline-tools;19.0':
        continue
    for item in package.findall('./archives/archive'):
        if item.findtext('./complete/url') == archive.name:
            checksum=item.find('./complete/checksum')
            expected=checksum.text.strip()
            actual=hashlib.file_digest(archive.open('rb'), checksum.attrib['type']).hexdigest()
            if actual != expected:
                raise SystemExit('Android commandline-tools checksum mismatch')
            print('Official Android repository checksum verified.')
            raise SystemExit(0)
raise SystemExit('Pinned Android tools not found in official repository manifest')
PY
  mkdir -p "$ENIGMA_SDK_DIR/cmdline-tools/version19"
  unzip -qo "$ENIGMA_SDK_CACHE/$ENIGMA_TOOLS_ARCHIVE" -d "$ENIGMA_SDK_DIR/cmdline-tools/version19"
fi
# Input file avoids SIGPIPE from `yes` masking SDK manager's own exit status.
python3 - "$ENIGMA_SDK_CACHE/licenses-input.txt" <<'PY'
from pathlib import Path
import sys
Path(sys.argv[1]).write_text('y\n'*100)
PY
"$ENIGMA_SDK_MANAGER" --sdk_root="$ENIGMA_SDK_DIR" --licenses < "$ENIGMA_SDK_CACHE/licenses-input.txt"
"$ENIGMA_SDK_MANAGER" --sdk_root="$ENIGMA_SDK_DIR" 'platform-tools' 'platforms;android-36' 'build-tools;36.1.0'
