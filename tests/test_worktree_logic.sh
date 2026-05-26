#!/bin/bash
set -euo pipefail

PASS=0
FAIL=0

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$actual" = "$expected" ]; then
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $desc"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        FAIL=$((FAIL + 1))
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/worktree_helpers.sh"

TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

# ── find_max_agent_number ────────────────────────────────────────────────────

assert_eq "max: nonexistent dir returns 0" \
    "0" "$(find_max_agent_number "$TMP/does_not_exist")"

assert_eq "max: empty dir returns 0" \
    "0" "$(find_max_agent_number "$TMP/empty" && mkdir -p "$TMP/empty" || find_max_agent_number "$TMP/empty")"

mkdir -p "$TMP/empty"
assert_eq "max: empty dir returns 0 (pre-created)" \
    "0" "$(find_max_agent_number "$TMP/empty")"

mkdir -p "$TMP/three/agent_1" "$TMP/three/agent_2" "$TMP/three/agent_3"
assert_eq "max: sequential agents 1-3 returns 3" \
    "3" "$(find_max_agent_number "$TMP/three")"

mkdir -p "$TMP/gap/agent_1" "$TMP/gap/agent_3"
assert_eq "max: agents with gap (1,3) returns 3" \
    "3" "$(find_max_agent_number "$TMP/gap")"

mkdir -p "$TMP/non_agent/agent_1" "$TMP/non_agent/other_dir" "$TMP/non_agent/workspace"
assert_eq "max: non-agent dirs are ignored" \
    "1" "$(find_max_agent_number "$TMP/non_agent")"

mkdir -p "$TMP/only_other/other_dir"
assert_eq "max: only non-agent dirs returns 0" \
    "0" "$(find_max_agent_number "$TMP/only_other")"

mkdir -p "$TMP/big/agent_10" "$TMP/big/agent_2"
assert_eq "max: agent_10 is correctly parsed as 10" \
    "10" "$(find_max_agent_number "$TMP/big")"

# ── compute_effective_n ──────────────────────────────────────────────────────

assert_eq "effective_n: no existing (0), N=3 -> 3" \
    "3" "$(compute_effective_n 0 3)"

assert_eq "effective_n: 5 existing, N=3 -> use all existing (5)" \
    "5" "$(compute_effective_n 5 3)"

assert_eq "effective_n: 5 existing, N=5 -> 5 (equal)" \
    "5" "$(compute_effective_n 5 5)"

assert_eq "effective_n: 5 existing, N=8 -> open all + new (8)" \
    "8" "$(compute_effective_n 5 8)"

assert_eq "effective_n: 0 existing, N=1 -> 1" \
    "1" "$(compute_effective_n 0 1)"

assert_eq "effective_n: 8 existing, N=9 -> 9" \
    "9" "$(compute_effective_n 8 9)"

assert_eq "effective_n: 8 existing, N=1 -> use all existing (8)" \
    "8" "$(compute_effective_n 8 1)"

# ── integration: worktree creation logic ────────────────────────────────────
# Simulate the main script's loop logic without git/tmux side effects

simulate_worktree_run() {
    local base_dir="$1"
    local requested_n="$2"
    local existing_max
    existing_max=$(find_max_agent_number "$base_dir")
    local effective_n
    effective_n=$(compute_effective_n "$existing_max" "$requested_n")
    for i in $(seq 1 "$effective_n"); do
        local wtree="$base_dir/agent_${i}"
        if [ ! -d "$wtree" ]; then
            mkdir -p "$wtree"
            echo "created:$i"
        else
            echo "reused:$i"
        fi
    done
    echo "total:$effective_n"
}

# No existing worktrees, N=3: creates 3 new
output=$(simulate_worktree_run "$TMP/run_fresh" 3)
assert_eq "integration: fresh N=3 creates agent_1" "created:1" "$(echo "$output" | grep "^created:1")"
assert_eq "integration: fresh N=3 creates agent_2" "created:2" "$(echo "$output" | grep "^created:2")"
assert_eq "integration: fresh N=3 creates agent_3" "created:3" "$(echo "$output" | grep "^created:3")"
assert_eq "integration: fresh N=3 total=3" "total:3" "$(echo "$output" | grep "^total:")"

# 3 existing, N=2: reuses all 3, creates none
mkdir -p "$TMP/run_shrink/agent_1" "$TMP/run_shrink/agent_2" "$TMP/run_shrink/agent_3"
output=$(simulate_worktree_run "$TMP/run_shrink" 2)
assert_eq "integration: 3 existing N=2 reuses agent_1" "reused:1" "$(echo "$output" | grep "^reused:1")"
assert_eq "integration: 3 existing N=2 reuses agent_2" "reused:2" "$(echo "$output" | grep "^reused:2")"
assert_eq "integration: 3 existing N=2 reuses agent_3" "reused:3" "$(echo "$output" | grep "^reused:3")"
assert_eq "integration: 3 existing N=2 total=3" "total:3" "$(echo "$output" | grep "^total:")"

# 3 existing, N=5: reuses 3 existing, creates 2 new
mkdir -p "$TMP/run_grow/agent_1" "$TMP/run_grow/agent_2" "$TMP/run_grow/agent_3"
output=$(simulate_worktree_run "$TMP/run_grow" 5)
assert_eq "integration: 3 existing N=5 reuses agent_1" "reused:1" "$(echo "$output" | grep "^reused:1")"
assert_eq "integration: 3 existing N=5 reuses agent_3" "reused:3" "$(echo "$output" | grep "^reused:3")"
assert_eq "integration: 3 existing N=5 creates agent_4" "created:4" "$(echo "$output" | grep "^created:4")"
assert_eq "integration: 3 existing N=5 creates agent_5" "created:5" "$(echo "$output" | grep "^created:5")"
assert_eq "integration: 3 existing N=5 total=5" "total:5" "$(echo "$output" | grep "^total:")"

# ── summary ──────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
