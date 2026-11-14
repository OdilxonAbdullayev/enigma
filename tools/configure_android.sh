#!/usr/bin/env bash
# Write only machine-local editor paths, never release signing credentials.
set -euo pipefail
ENIGMA_SDK_DIR="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/workspace/.tools/android-sdk}}"
ENIGMA_JAVA_DIR="${JAVA_HOME:-$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")}"
ENIGMA_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/godot"
mkdir -p "$ENIGMA_CONFIG_DIR"
# Godot 4.6 uses editor_settings-4.6.tres. An existing file is preserved except these keys.
python3 - "$ENIGMA_CONFIG_DIR/editor_settings-4.6.tres" "$ENIGMA_SDK_DIR" "$ENIGMA_JAVA_DIR" <<'PY'
import json, pathlib, re, sys
path=pathlib.Path(sys.argv[1])
text=path.read_text() if path.exists() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
for key,value in {'export/android/android_sdk_path':sys.argv[2], 'export/android/java_sdk_path':sys.argv[3]}.items():
    line=f'{key} = {json.dumps(value)}'
    pattern=r'^'+re.escape(key)+r' = .*?$'
    text=re.sub(pattern,lambda _:line,text,flags=re.M) if re.search(pattern,text,re.M) else text.rstrip()+'\n'+line+'\n'
path.write_text(text)
PY
