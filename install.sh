#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="/usr/local/bin/10xCode"

ln -sf "$SCRIPT_DIR/10xCode" "$TARGET"
echo "Installed: 10xCode -> $TARGET"
echo "Usage: cd into any project, then run: 10xCode --8"
