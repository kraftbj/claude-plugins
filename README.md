# Claude Code Plugins

A collection of Claude Code plugins.

## Installation

To use plugins from this marketplace, add it to your Claude Code configuration:

```bash
claude /plugin marketplace add /path/to/claude-plugins
```

Or add to your `~/.claude/settings.json`:

```json
{
  "plugins": {
    "marketplaces": [
      "/Users/kraft/code/claude-plugins"
    ]
  }
}
```

## Available Plugins

| Plugin | Description |
|--------|-------------|
| [agents-md-support](./agents-md-support/) | Adds support for AGENTS.md open standard as a fallback for CLAUDE.md |

## Plugin Details

### agents-md-support

Enables Claude Code to work with repositories that use the [AGENTS.md](https://agents.md/) open standard (60,000+ projects). When no CLAUDE.md file is present, the plugin automatically loads AGENTS.md as project context.

**Features:**
- CLAUDE.md always takes precedence (no breaking changes)
- Automatic fallback to AGENTS.md when no CLAUDE.md exists
- Support for `@AGENTS.md` include directive in CLAUDE.md files

[Full documentation](./agents-md-support/README.md)
