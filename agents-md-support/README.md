# AGENTS.md Support Plugin

This plugin adds support for the [AGENTS.md](https://agents.md/) open standard to Claude Code. It provides AGENTS.md as a fallback when no CLAUDE.md file is present, enabling Claude Code to work seamlessly with the 60,000+ open-source projects that use AGENTS.md.

## How It Works

The plugin uses a SessionStart hook to check for instruction files:

1. **Check for CLAUDE.md first** - If CLAUDE.md exists (at project root or in `.claude/`), the plugin does nothing and lets Claude Code's native handling take over
2. **Fall back to AGENTS.md** - If no CLAUDE.md is found, the plugin looks for AGENTS.md
3. **Load as context** - If AGENTS.md exists, its content is loaded as additional context for Claude

This ensures CLAUDE.md always takes precedence over AGENTS.md.

## Installation

### From the Plugin Directory

```bash
# Navigate to your project
cd /path/to/your/project

# Install the plugin
claude plugin install /path/to/claude-code/plugins/agents-md-support
```

### Manual Installation

1. Copy the `agents-md-support` folder to your project's `.claude/plugins/` directory
2. Or add it to your global plugins at `~/.claude/plugins/`

## File Priority

The plugin follows this priority order:

| Priority | File | Behavior |
|----------|------|----------|
| 1 | `./CLAUDE.md` | Native handling (plugin exits) |
| 2 | `./.claude/CLAUDE.md` | Native handling (plugin exits) |
| 3 | `./AGENTS.md` | Loaded by plugin |
| 4 | `./.claude/AGENTS.md` | Loaded by plugin |

## Combining CLAUDE.md and AGENTS.md

If you want Claude-specific instructions while also using your AGENTS.md, create a CLAUDE.md file with an `@AGENTS.md` include:

```markdown
# My Project - Claude Instructions

## Claude-Specific Features

- Use `/agent:code-reviewer` for PR reviews
- Prefer the Task tool for multi-step operations

## Standard Agent Instructions

@AGENTS.md
```

This pattern lets you:
- Add Claude-specific features and preferences
- Inherit base instructions from AGENTS.md
- Keep AGENTS.md working for other tools (Cursor, Copilot, etc.)

**Tip:** If your CLAUDE.md would be identical to AGENTS.md, simply don't create a CLAUDE.md file. Only create one when you need Claude-specific customizations.

## Supported File Names

The plugin recognizes these case variations:
- `AGENTS.md` (recommended)
- `AGENTS.MD`
- `agents.md`

## Example

### Repository with only AGENTS.md

```
my-project/
├── AGENTS.md          # Contains project instructions
├── src/
└── package.json
```

When you run `claude` in this project, the plugin loads AGENTS.md content automatically.

### Repository with both files

```
my-project/
├── AGENTS.md          # Generic agent instructions
├── CLAUDE.md          # Claude-specific additions + @AGENTS.md
├── src/
└── package.json
```

Claude Code uses CLAUDE.md (which can include AGENTS.md via the `@` directive).

## Technical Details

### Hook Implementation

The plugin uses a `SessionStart` hook that:
1. Runs at the start of each Claude Code session
2. Checks for existing CLAUDE.md files
3. Loads AGENTS.md content as `additionalContext` if appropriate

### Context Label

AGENTS.md content appears in the system context with a header indicating its source:

```
The following instructions are from AGENTS.md (AGENTS.md), an open standard
for AI coding agent guidance. These instructions apply to this project:

---

[AGENTS.md content here]
```

## Limitations

This plugin is an interim solution until native AGENTS.md support is added to Claude Code. Current limitations:

1. **Subdirectory AGENTS.md** - Only checks project root and `.claude/` directory, not subdirectories of modified files
2. **No `@` directive processing** - Doesn't process include directives within AGENTS.md files
3. **Single file only** - Loads one AGENTS.md file (root takes priority over `.claude/`)

These limitations will be addressed when native support is implemented.

## Related

- [AGENTS.md Standard](https://agents.md/)
- [GitHub Issue #6235](https://github.com/anthropics/claude-code/issues/6235)
- [CLAUDE.md Documentation](https://code.claude.com/docs/en/claude-md)
