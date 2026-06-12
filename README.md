# Dev Container Features

> A collection of [dev container Features](https://containers.dev/implementors/features/) for AI coding assistants and developer tools.

## Features

| Feature | Description |
|---------|-------------|
| [mimo-code](src/mimo-code/) | MiMo Code CLI (`mimo`) - AI-powered coding assistant by Xiaomi |
| [codebuddy](src/codebuddy/) | CodeBuddy Code CLI (`codebuddy`) - AI-powered coding assistant |
| [cc-switch](src/cc-switch/) | CC-Switch CLI (`cc-switch`) - All-in-one manager for AI coding assistants |

## Usage

Add one or more Features to your `devcontainer.json`:

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/unfallenwill/devcontainer-features/mimo-code:1": {},
        "ghcr.io/unfallenwill/devcontainer-features/codebuddy:1": {},
        "ghcr.io/unfallenwill/devcontainer-features/cc-switch:1": {}
    }
}
```

With a specific version:

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/unfallenwill/devcontainer-features/codebuddy:1": {
            "version": "2.106.0"
        }
    }
}
```

All Features support a `version` option (default: `"latest"`).

### `mimo-code`

Installs [MiMo Code](https://mimo.xiaomi.com) CLI.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `"latest"` | Version to install (e.g. `"0.1.0"`) |

### `codebuddy`

Installs [CodeBuddy Code](https://www.codebuddy.cn) CLI.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `"latest"` | Version to install (e.g. `"2.106.0"`) |

### `cc-switch`

Installs [CC-Switch CLI](https://github.com/SaladDay/cc-switch-cli) - manager for Claude Code, Codex, Gemini CLI, OpenCode, Hermes, OpenClaw.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `"latest"` | Version to install (e.g. `"5.8.2"`) |

## Repo Structure

```
├── src/
│   ├── mimo-code/          # MiMo Code Feature
│   │   ├── devcontainer-feature.json
│   │   ├── install.sh
│   │   └── README.md
│   ├── codebuddy/          # CodeBuddy Code Feature
│   │   ├── devcontainer-feature.json
│   │   ├── install.sh
│   │   └── README.md
│   └── cc-switch/          # CC-Switch CLI Feature
│       ├── devcontainer-feature.json
│       ├── install.sh
│       └── README.md
├── test/                   # Test scenarios (mirrors src/)
├── .github/workflows/
│   ├── release.yaml        # Publish to GHCR
│   ├── test.yaml           # CI tests
│   └── validate.yml        # Validate feature metadata
```

## Publishing

Features are automatically published to GHCR on push to `main` via [release.yaml](.github/workflows/release.yaml).

You can also publish manually:

```bash
npx -y @devcontainers/cli features publish \
  --registry ghcr.io \
  --namespace unfallenwill/devcontainer-features \
  ./src
```

### Marking Features Public

By default, GHCR packages are private. To make them publicly accessible, go to each package's settings page and set visibility to `public`:

```
https://github.com/users/unfallenwill/packages/container/devcontainer-features%2F<feature-name>/settings
```

### Using private Features in Codespaces

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/unfallenwill/devcontainer-features/codebuddy:1": {}
    },
    "customizations": {
        "codespaces": {
            "repositories": {
                "unfallenwill/devcontainer-features": {
                    "permissions": {
                        "packages": "read",
                        "contents": "read"
                    }
                }
            }
        }
    }
}
```
