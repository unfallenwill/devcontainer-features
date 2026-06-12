# Dev Container Feature: MiMo Code

> This repo provides a [dev container Feature](https://containers.dev/implementors/features/) that installs [MiMo Code](https://mimo.xiaomi.com) (the `mimo` CLI) into a development container.

## Contents

This repository contains one Feature — `mimo-code`. It installs the MiMo Code CLI binary from [GitHub Releases](https://github.com/XiaomiMiMo/MiMo-Code).

### `mimo-code`

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/unfallenwill/devcontainer-features/mimo-code:1": {}
    }
}
```

With a specific version:

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/unfallenwill/devcontainer-features/mimo-code:1": {
            "version": "0.1.0"
        }
    }
}
```

After installation, `mimo` will be available on `PATH`:

```bash
$ mimo --version
```

#### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `"latest"` | The version of MiMo Code to install (e.g. `"0.1.0"`). Use `"latest"` for the newest release. |

## Repo and Feature Structure

```
├── src
│   └── mimo-code
│       ├── devcontainer-feature.json
│       └── install.sh
├── test
│   └── mimo-code
│       ├── scenarios.json
│       ├── test.sh
│       └── latest.sh
├── .github
│   └── workflows
│       ├── release.yaml
│       ├── test.yaml
│       └── validate.yml
...
```

An [implementing tool](https://containers.dev/supporting#tools) will composite [the documented dev container properties](https://containers.dev/implementors/features/#devcontainer-feature-json-properties) from the feature's `devcontainer-feature.json` file, and execute the `install.sh` entrypoint script in the container during build time.

### Options

All available options for a Feature are declared in `devcontainer-feature.json`. Options are exported as Feature-scoped environment variables. The option name is capitalized and sanitized according to [option resolution](https://containers.dev/implementors/features/#option-resolution).

For example, the `version` option becomes the `$VERSION` environment variable in `install.sh`.

## Distributing Features

### Versioning

Features are individually versioned by the `version` attribute in `devcontainer-feature.json`. Features are versioned according to the semver specification. More details can be found in [the dev container Feature specification](https://containers.dev/implementors/features/#versioning).

### Publishing

> NOTE: The Distribution spec can be [found here](https://containers.dev/implementors/features-distribution/).
>
> While any registry [implementing the OCI Distribution spec](https://github.com/opencontainers/distribution-spec) can be used, this template leverages GHCR (GitHub Container Registry) as the backing registry.

This repo contains a **GitHub Action** [workflow](.github/workflows/release.yaml) that will publish each Feature to GHCR.

*Allow GitHub Actions to create and approve pull requests* should be enabled in the repository's `Settings > Actions > General > Workflow permissions` for auto generation of `src/<feature>/README.md` per Feature (which merges any existing `src/<feature>/NOTES.md`).

By default, each Feature will be prefixed with the `<owner>/<repo>` namespace:

```
ghcr.io/unfallenwill/devcontainer-features/mimo-code:1
```

The provided GitHub Action will also publish a "metadata" package with just the namespace, eg: `ghcr.io/unfallenwill/devcontainer-features`. This contains information useful for tools aiding in Feature discovery.

### Marking Feature Public

Note that by default, GHCR packages are marked as `private`. To stay within the free tier, Features need to be marked as `public`.

This can be done by navigating to the Feature's "package settings" page in GHCR, and setting the visibility to `public`. The URL may look something like:

```
https://github.com/users/<owner>/packages/container/<repo>%2Fmimo-code/settings
```

### Adding Features to the Index

If you'd like your Features to appear in the [public index](https://containers.dev/features) so that other community members can find them, you can do the following:

* Go to [github.com/devcontainers/devcontainers.github.io](https://github.com/devcontainers/devcontainers.github.io)
* Open a PR to modify the [collection-index.yml](https://github.com/devcontainers/devcontainers.github.io/blob/gh-pages/_data/collection-index.yml) file

#### Using private Features in Codespaces

For any Features hosted in GHCR that are kept private, the `GITHUB_TOKEN` access token in your environment will need to have `package:read` and `contents:read` for the associated repository.

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/unfallenwill/devcontainer-features/mimo-code:1": {}
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
