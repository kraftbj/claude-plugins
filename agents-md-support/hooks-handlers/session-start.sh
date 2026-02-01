#!/usr/bin/env bash

# AGENTS.md Support Plugin - SessionStart Hook
#
# This hook provides AGENTS.md support for Claude Code by:
# 1. Checking if a CLAUDE.md file exists (if so, skip - native handling takes over)
# 2. Looking for AGENTS.md files in the project
# 3. Loading AGENTS.md content as additional context if no CLAUDE.md is present
#
# This follows the agents.md open standard: https://agents.md/

set -e

# Get the working directory from the hook input
# The hook receives JSON input on stdin with session information
WORK_DIR="${CLAUDE_WORKING_DIR:-$(pwd)}"

# Function to find instruction file (prefers CLAUDE.md, falls back to AGENTS.md)
find_instruction_file() {
    local dir="$1"
    local type="$2"  # 'claude' or 'agents'

    if [ "$type" = "claude" ]; then
        local files=("CLAUDE.md" "CLAUDE.MD" "claude.md")
    else
        local files=("AGENTS.md" "AGENTS.MD" "agents.md")
    fi

    for file in "${files[@]}"; do
        local filepath="$dir/$file"
        if [ -f "$filepath" ]; then
            echo "$filepath"
            return 0
        fi
    done

    return 1
}

# Check if CLAUDE.md exists at project root
# If it does, we don't load AGENTS.md (CLAUDE.md takes precedence)
if find_instruction_file "$WORK_DIR" "claude" > /dev/null 2>&1; then
    # CLAUDE.md exists, let native handling take over
    # Output empty JSON to indicate no additional context needed
    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart"
  }
}
EOF
    exit 0
fi

# Also check .claude directory for CLAUDE.md
CLAUDE_DIR="$WORK_DIR/.claude"
if [ -d "$CLAUDE_DIR" ]; then
    if find_instruction_file "$CLAUDE_DIR" "claude" > /dev/null 2>&1; then
        # CLAUDE.md exists in .claude directory, let native handling take over
        cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart"
  }
}
EOF
        exit 0
    fi
fi

# No CLAUDE.md found, look for AGENTS.md
AGENTS_FILE=""

# Check project root first
if AGENTS_FILE=$(find_instruction_file "$WORK_DIR" "agents" 2>/dev/null); then
    :  # Found at root
# Check .claude directory
elif [ -d "$CLAUDE_DIR" ] && AGENTS_FILE=$(find_instruction_file "$CLAUDE_DIR" "agents" 2>/dev/null); then
    :  # Found in .claude
fi

# If no AGENTS.md found, exit with empty context
if [ -z "$AGENTS_FILE" ] || [ ! -f "$AGENTS_FILE" ]; then
    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart"
  }
}
EOF
    exit 0
fi

# Read AGENTS.md content
AGENTS_CONTENT=$(cat "$AGENTS_FILE")

# Escape the content for JSON
# This handles newlines, quotes, backslashes, and other special characters
escape_json() {
    local content="$1"
    # Use python for reliable JSON escaping if available, otherwise use sed
    if command -v python3 &> /dev/null; then
        python3 -c "import json,sys; print(json.dumps(sys.stdin.read())[1:-1])" <<< "$content"
    elif command -v python &> /dev/null; then
        python -c "import json,sys; print(json.dumps(sys.stdin.read())[1:-1])" <<< "$content"
    else
        # Fallback: basic escaping with sed
        echo "$content" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g' -e 's/\t/\\t/g'
    fi
}

ESCAPED_CONTENT=$(escape_json "$AGENTS_CONTENT")

# Get the relative path for display
RELATIVE_PATH="${AGENTS_FILE#$WORK_DIR/}"
if [ "$RELATIVE_PATH" = "$AGENTS_FILE" ]; then
    RELATIVE_PATH=$(basename "$AGENTS_FILE")
fi

# Build the context header
CONTEXT_HEADER="The following instructions are from AGENTS.md (${RELATIVE_PATH}), an open standard for AI coding agent guidance. These instructions apply to this project:\n\n---\n\n"

# Output the AGENTS.md content as additional context
cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${CONTEXT_HEADER}${ESCAPED_CONTENT}"
  }
}
EOF

exit 0
