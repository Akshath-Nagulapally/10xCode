#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/agents.yaml"
SESSION="agents"
N=2

# Parse --N flag (e.g. --8, --10)
for arg in "$@"; do
    if [[ "$arg" =~ ^--([0-9]+)$ ]]; then
        N="${BASH_REMATCH[1]}"
    fi
done

# Load agent names from YAML (cycles if N > number of agents defined)
AGENT_DATA=$(python3 - "$CONFIG" "$N" <<'PYEOF'
import yaml, sys, math

config_path, n = sys.argv[1], int(sys.argv[2])
with open(config_path) as f:
    data = yaml.safe_load(f)

agents = data['agents']
for i in range(n):
    a = agents[i % len(agents)]
    print(a['name'])
    print(a['instructions'])
PYEOF
)

NAMES=()
INSTRUCTIONS=()
while IFS= read -r name && IFS= read -r instr; do
    NAMES+=("$name")
    INSTRUCTIONS+=("$instr")
done <<< "$AGENT_DATA"

# Compute square-ish grid: cols = round(sqrt(N)), rows fills up
COLS=$(python3 -c "import math; n=$N; print(max(1, round(math.sqrt(n))))")

# Kill existing session and start fresh
tmux kill-session -t "$SESSION" 2>/dev/null || true
tmux new-session -d -s "$SESSION"

# Create N-1 additional panes
for i in $(seq 1 $((N-1))); do
    tmux split-window -d -t "$SESSION"
done

# Apply layout: 2 panes stacked, otherwise tiled (square grid)
if [ "$N" -eq 1 ]; then
    : # single pane, nothing to do
elif [ "$N" -eq 2 ]; then
    tmux select-layout -t "$SESSION" even-vertical
else
    tmux select-layout -t "$SESSION" tiled
fi

# Launch claude in each pane with instructions piped as initial prompt
for i in "${!NAMES[@]}"; do
    INSTR_PATH="$SCRIPT_DIR/${INSTRUCTIONS[$i]}"
    tmux send-keys -t "$SESSION:0.$i" "claude < \"$INSTR_PATH\"" Enter
done

tmux attach-session -t "$SESSION"
