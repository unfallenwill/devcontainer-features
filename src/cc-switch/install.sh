#!/bin/sh
set -eu

REPO="SaladDay/cc-switch-cli"
BIN_NAME="cc-switch"
RELEASES_URL="https://github.com/${REPO}/releases"

# Determine install directory under the remote user's home
if [ -n "${_REMOTE_USER_HOME:-}" ]; then
    INSTALL_DIR="${_REMOTE_USER_HOME}/.local/bin"
else
    INSTALL_DIR="${HOME}/.local/bin"
fi

TARGET="${INSTALL_DIR}/${BIN_NAME}"

VERSION="${VERSION:-latest}"
# Ensure version has 'v' prefix for GitHub download URL (unless 'latest')
if [ "$VERSION" != "latest" ]; then
    case "$VERSION" in
        v*) ;;
        *)  VERSION="v${VERSION}" ;;
    esac
fi

# ── helpers ──────────────────────────────────────────────────────────

detect_package_manager() {
    for pm in apt-get apk dnf yum; do
        if command -v "$pm" >/dev/null 2>&1; then
            case "$pm" in
                apt-get) echo "apt" ;;
                *) echo "$pm" ;;
            esac
            return 0
        fi
    done
    echo "unknown"
    return 1
}

install_packages() {
    pkg_manager="$1"
    shift
    packages="$*"

    case "$pkg_manager" in
        apt)
            apt-get update -qq
            apt-get install -y -qq $packages
            ;;
        apk)
            apk add --no-cache $packages
            ;;
        dnf|yum)
            "$pkg_manager" install -y $packages
            ;;
        *)
            echo "WARNING: Unsupported package manager. Cannot install: $packages"
            return 1
            ;;
    esac
}

ensure_dependencies() {
    local missing=""

    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        missing="curl $missing"
    fi

    if ! command -v tar >/dev/null 2>&1; then
        missing="tar $missing"
    fi

    if [ -n "$missing" ]; then
        PKG_MANAGER=$(detect_package_manager) || true
        if [ "$PKG_MANAGER" != "unknown" ]; then
            echo "Installing missing dependencies: $missing"
            install_packages "$PKG_MANAGER" $missing
        else
            echo "ERROR: Missing required tools: $missing"
            exit 1
        fi
    fi
}

download() {
    local url=$1 output=$2
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$output" "$url"
    else
        echo "ERROR: need curl or wget"
        exit 1
    fi
}

# ── platform detection ───────────────────────────────────────────────

detect_asset() {
    local os arch
    os="$(uname -s 2>/dev/null || true)"
    arch="$(uname -m 2>/dev/null || true)"

    case "${os}" in
        Darwin)
            # Universal binary works on both Apple Silicon and Intel
            ASSET_NAME="cc-switch-cli-darwin-universal.tar.gz"
            ;;
        Linux)
            case "${arch}" in
                x86_64|amd64)
                    # Prefer musl (static) build, fallback to glibc
                    ASSET_NAME="cc-switch-cli-linux-x64-musl.tar.gz"
                    ASSET_FALLBACK="cc-switch-cli-linux-x64.tar.gz"
                    ;;
                aarch64|arm64)
                    ASSET_NAME="cc-switch-cli-linux-arm64-musl.tar.gz"
                    ASSET_FALLBACK="cc-switch-cli-linux-arm64.tar.gz"
                    ;;
                *)
                    echo "ERROR: Unsupported Linux architecture: ${arch}"
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo "ERROR: Unsupported OS: ${os}"
            exit 1
            ;;
    esac
}

# ── download & install ───────────────────────────────────────────────

do_download() {
    local url dest
    if [ "$VERSION" = "latest" ]; then
        url="${RELEASES_URL}/latest/download/${1}"
    else
        url="${RELEASES_URL}/download/${VERSION}/${1}"
    fi
    dest="${TMPDIR}/${1}"
    echo "Downloading ${1}"
    download "$url" "$dest"
}

do_install() {
    mkdir -p "${INSTALL_DIR}"

    echo "Extracting archive"
    tar -xzf "${TMPDIR}/${ASSET_NAME}" -C "${TMPDIR}"

    if [ ! -f "${TMPDIR}/${BIN_NAME}" ]; then
        echo "ERROR: Binary '${BIN_NAME}' not found in archive."
        exit 1
    fi

    cp "${TMPDIR}/${BIN_NAME}" "${TARGET}"
    chmod 755 "${TARGET}"
}

# ── PATH setup ───────────────────────────────────────────────────────

configure_path() {
    if [ -z "${_REMOTE_USER:-}" ] || [ -z "${_REMOTE_USER_HOME:-}" ]; then
        return
    fi

    # Ensure ownership is correct
    chown -R "$_REMOTE_USER" "${_REMOTE_USER_HOME}/.local" 2>/dev/null || true

    # Add ~/.local/bin to PATH via shell profile if not already present
    local profile=""
    if [ -f "${_REMOTE_USER_HOME}/.zshrc" ]; then
        profile="${_REMOTE_USER_HOME}/.zshrc"
    elif [ -f "${_REMOTE_USER_HOME}/.bashrc" ]; then
        profile="${_REMOTE_USER_HOME}/.bashrc"
    fi

    if [ -n "$profile" ] && ! grep -q '/.local/bin' "$profile" 2>/dev/null; then
        echo "" >> "$profile"
        echo "export PATH=\"\${HOME}/.local/bin:\${PATH}\"" >> "$profile"
        chown "$_REMOTE_USER" "$profile" 2>/dev/null || true
    fi
}

# ── main ─────────────────────────────────────────────────────────────

main() {
    echo "Activating feature 'cc-switch'"

    ensure_dependencies
    detect_asset

    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    # Try primary asset, fallback if needed
    if ! do_download "$ASSET_NAME" 2>/dev/null; then
        if [ -n "${ASSET_FALLBACK:-}" ]; then
            echo "Primary download failed, trying fallback: ${ASSET_FALLBACK}"
            ASSET_NAME="$ASSET_FALLBACK"
            do_download "$ASSET_NAME"
        else
            echo "ERROR: Download failed"
            exit 1
        fi
    fi

    do_install
    configure_path

    if command -v "${TARGET}" >/dev/null 2>&1 || [ -x "${TARGET}" ]; then
        echo "CC-Switch CLI installed successfully!"
        "${TARGET}" --version || true
    else
        echo "ERROR: CC-Switch CLI installation failed!"
        exit 1
    fi
}

main
