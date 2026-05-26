#!/bin/bash

# Returns the highest agent_N number found in base_dir, or 0 if none exist.
find_max_agent_number() {
    local base_dir="$1"
    local max=0
    for dir in "$base_dir"/agent_*; do
        if [ -d "$dir" ]; then
            local num="${dir##*/agent_}"
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -gt "$max" ]; then
                max="$num"
            fi
        fi
    done
    echo "$max"
}

# Returns max(existing_max, requested_n).
# If existing worktrees outnumber the request, use all existing ones.
# If request exceeds existing, open all existing plus create the difference.
compute_effective_n() {
    local existing_max="$1"
    local requested_n="$2"
    if [ "$existing_max" -gt "$requested_n" ]; then
        echo "$existing_max"
    else
        echo "$requested_n"
    fi
}
