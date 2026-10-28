#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ID=$(jq -r '.id' "$SCRIPT_DIR/manifest.json")
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

echo "Installing $PLUGIN_ID..."

mkdir -p "$PLUGIN_DIR"
cp "$SCRIPT_DIR/BarWidget.qml" "$SCRIPT_DIR/cpu-temp.sh" "$SCRIPT_DIR/manifest.json" "$PLUGIN_DIR/"
chmod +x "$PLUGIN_DIR/cpu-temp.sh"

if ! command -v omarchy >/dev/null 2>&1; then
  echo "Omarchy CLI not found. Manual steps:"
  echo "  1. Add { \"id\": \"$PLUGIN_ID\" } to ~/.config/omarchy/shell.json under bar.layout.right"
  echo "  2. Restart the shell (omarchy restart shell)"
  exit 0
fi

omarchy plugin enable "$PLUGIN_ID" || true

if omarchy bar put "$PLUGIN_ID" --before omarchy.power 2>/dev/null; then
  echo "$PLUGIN_ID placed on the bar (before omarchy.power)"
else
  omarchy bar put "$PLUGIN_ID"
  echo "$PLUGIN_ID placed on the bar"
fi

omarchy restart shell
echo "Done. The widget should appear in the status bar shortly."
