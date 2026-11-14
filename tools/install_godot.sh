#!/usr/bin/env bash
# Install pinned official Godot binaries with release SHA-512 verification.
set -euo pipefail
GODOT_VERSION=4.6.3
GODOT_RELEASE="${GODOT_VERSION}-stable"
ENIGMA_TOOLS_DIR="${ENIGMA_TOOLS_DIR:-/workspace/.tools/godot}"
mkdir -p "$ENIGMA_TOOLS_DIR"
ENIGMA_RELEASE_URL="https://github.com/godotengine/godot/releases/download/${GODOT_RELEASE}"
ENIGMA_CHECKSUMS="$ENIGMA_TOOLS_DIR/SHA512-SUMS-${GODOT_RELEASE}.txt"
curl --fail --location --retry 3 --silent --show-error "$ENIGMA_RELEASE_URL/SHA512-SUMS.txt" -o "$ENIGMA_CHECKSUMS"
verify_archive() {
  local archive="$1"
  awk -v name="$archive" '$2 == name' "$ENIGMA_CHECKSUMS" > "$ENIGMA_TOOLS_DIR/selected.sha512"
  test -s "$ENIGMA_TOOLS_DIR/selected.sha512"
  (cd "$ENIGMA_TOOLS_DIR"; sha512sum --check selected.sha512)
}
ENIGMA_INSTALLED_GODOT=$(command -v godot || true)
if [[ -n "$ENIGMA_INSTALLED_GODOT" ]] && [[ "$("$ENIGMA_INSTALLED_GODOT" --version)" == "$GODOT_VERSION.stable."* ]]; then
  # Reuse the managed runtime instead of downloading a second editor.
  if [[ "$(readlink -f "$ENIGMA_INSTALLED_GODOT")" != "$(readlink -f "$ENIGMA_TOOLS_DIR/godot" 2>/dev/null || true)" ]]; then
    ln -sf "$ENIGMA_INSTALLED_GODOT" "$ENIGMA_TOOLS_DIR/godot"
  fi
else
  ENIGMA_BINARY_ARCHIVE="Godot_v${GODOT_RELEASE}_linux.x86_64.zip"
  curl --fail --location --retry 3 --silent --show-error "$ENIGMA_RELEASE_URL/$ENIGMA_BINARY_ARCHIVE" -o "$ENIGMA_TOOLS_DIR/$ENIGMA_BINARY_ARCHIVE"
  verify_archive "$ENIGMA_BINARY_ARCHIVE"
  unzip -qo "$ENIGMA_TOOLS_DIR/$ENIGMA_BINARY_ARCHIVE" -d "$ENIGMA_TOOLS_DIR/binary"
  install -m 755 "$ENIGMA_TOOLS_DIR/binary/Godot_v${GODOT_RELEASE}_linux.x86_64" "$ENIGMA_TOOLS_DIR/godot"
fi
"$ENIGMA_TOOLS_DIR/godot" --version
if [[ "${1:-}" == "--templates" ]]; then
  ENIGMA_TEMPLATE_ARCHIVE="Godot_v${GODOT_RELEASE}_export_templates.tpz"
  if [[ ! -f "$ENIGMA_TOOLS_DIR/$ENIGMA_TEMPLATE_ARCHIVE" ]]; then
    curl --fail --location --retry 3 --silent --show-error "$ENIGMA_RELEASE_URL/$ENIGMA_TEMPLATE_ARCHIVE" -o "$ENIGMA_TOOLS_DIR/$ENIGMA_TEMPLATE_ARCHIVE"
  fi
  verify_archive "$ENIGMA_TEMPLATE_ARCHIVE"
  ENIGMA_TEMPLATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${GODOT_VERSION}.stable"
  mkdir -p "$ENIGMA_TEMPLATE_DIR"
  unzip -qo "$ENIGMA_TOOLS_DIR/$ENIGMA_TEMPLATE_ARCHIVE" 'templates/android_debug.apk' 'templates/android_release.apk' 'templates/linux_debug.x86_64' 'templates/linux_release.x86_64' 'templates/version.txt' -d "$ENIGMA_TOOLS_DIR/extracted"
  cp -a "$ENIGMA_TOOLS_DIR/extracted/templates/." "$ENIGMA_TEMPLATE_DIR/"
fi
