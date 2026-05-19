# 10xCode

Launch N claude agents in a tmux grid, all working inside your current project directory.

## Setup

**1. Clone the repo**
```bash
git clone https://github.com/Akshath-Nagulapally/10xCode.git
cd 10xCode
```

**2. Install the command**
```bash
./install.sh
```

This symlinks `10xCode` into `/usr/local/bin` so it's available anywhere.

---

## Usage

`cd` into any project directory and run:

```bash
10xCode          # 2 agents (default)
10xCode --4      # 4 agents in a 2x2 grid
10xCode --8      # 8 agents in a 3x3 grid
10xCode --10     # 10 agents in a 4x3 grid
```

Each pane opens in your project directory with claude pre-loaded with the instructions from `initial_instructions.md`.

The tmux session is named after your project folder (e.g. `10x_my_project`), so you can run multiple projects simultaneously without conflicts.

**To exit:** `Ctrl+b d` to detach, or `tmux kill-session -t 10x_<project>` to shut it down.

---

## Layout

| Count | Grid |
|-------|------|
| 1 | single pane |
| 2 | 2 rows × 1 col (stacked) |
| 4 | 2 × 2 |
| 8 | 3 × 3 (8 filled) |
| 9 | 3 × 3 |
| 10 | 4 × 3 |

For any N, the grid stays as square as possible (closest to √N columns).

---

## Configuration

### `agents.yaml`
Defines the agent names and which instructions file they use. All 8 slots point to the same instructions by default — change this if you want different agents to have different instructions.

```yaml
agents:
  - name: agent_1
    instructions: initial_instructions.md
  - name: agent_2
    instructions: initial_instructions.md
  # ...
```

If you run `10xCode --10` with only 8 agents defined, the list cycles.

### `initial_instructions.md`
The instructions piped into each claude instance on startup. Edit this to change what every agent does when it launches.

The default instructs each agent to:
1. Understand the existing codebase
2. Create a relevant git branch
3. Plan a skeleton before writing code
4. Write a test plan
5. Run existing tests to establish a baseline
6. Implement the solution
7. Write and run new tests
8. Run linting/code quality checks

---

## Requirements

- [tmux](https://github.com/tmux/tmux)
- [claude](https://claude.ai/code) (Claude Code CLI)
- Python 3 (stdlib only, no extra packages)
