# MiMo Code

Installs the MiMo Code CLI (`mimo`) - an AI-powered coding assistant by Xiaomi.

## Example Usage

```json
"features": {
    "ghcr.io/unfallenwill/devcontainer-features/mimo-code:1": {}
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `"latest"` | The version of MiMo Code to install (e.g. `"0.1.0"`). Use `"latest"` for the newest release. |

## Customizations

### VS Code Extensions

- `MiMo.mi-mo`

## OS Support

This feature installs a pre-built native binary and supports:

| OS | Architecture |
|----|-------------|
| Linux | x86_64, aarch64 |
| Linux (musl/Alpine) | x86_64, aarch64 |
| macOS | x86_64, aarch64 |

## Notes

The binary is installed to `~/.mimocode/bin/mimo` and symlinked to `/usr/local/bin/mimo`.
