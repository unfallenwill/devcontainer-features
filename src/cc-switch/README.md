# CC-Switch CLI

Installs [CC-Switch CLI](https://github.com/SaladDay/cc-switch-cli) (`cc-switch`) - an all-in-one manager for AI coding assistants.

## Supported Apps

- Claude Code
- Codex
- Gemini CLI
- OpenCode
- Hermes
- OpenClaw

## Example Usage

```json
{
    "features": {
        "ghcr.io/unfallenwill/devcontainer-features/cc-switch:1": {}
    }
}
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `version` | `latest` | Version of CC-Switch CLI to install (e.g. `5.8.2`). Use `latest` for the newest release. |

## Supported Platforms

- Linux (x86_64, arm64, musl and glibc)
- macOS (Universal binary for Apple Silicon and Intel)

## Usage

```bash
# Interactive TUI mode
cc-switch

# CLI mode
cc-switch provider list
cc-switch use <id>
cc-switch --app codex mcp sync
```
