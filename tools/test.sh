#!/usr/bin/env bash
set -euo pipefail
ENIGMA_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
ENIGMA_PARENT=$(dirname "$ENIGMA_ROOT")
export XDG_DATA_HOME="${ENIGMA_TEST_DATA:-$ENIGMA_PARENT/.enigma-tests/data}"
export XDG_CONFIG_HOME="${ENIGMA_TEST_CONFIG:-$ENIGMA_PARENT/.enigma-tests/config}"
export XDG_CACHE_HOME="${ENIGMA_TEST_CACHE:-$ENIGMA_PARENT/.enigma-tests/cache}"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$ENIGMA_ROOT/builds"
ENIGMA_GODOT="${GODOT_BIN:-godot}"
run_checked() {
  local label="$1"; shift
  local log="$ENIGMA_ROOT/builds/$label.log"
  "$@" > "$log" 2>&1 || { cat "$log"; return 1; }
  cat "$log"
  if rg -n 'SCRIPT ERROR:|^ERROR:|[1-9][0-9]* failures' "$log"; then
    return 1
  fi
}
run_checked import "$ENIGMA_GODOT" --headless --path "$ENIGMA_ROOT" --editor --import
for suite in state localization flow input; do
  run_checked "test-$suite" "$ENIGMA_GODOT" --headless --path "$ENIGMA_ROOT" --script "res://tests/test_$suite.gd"
done
