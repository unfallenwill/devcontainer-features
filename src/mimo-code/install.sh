#!/bin/sh
set -eu

# Detect the package manager and install required dependencies
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

    if ! command -v curl >/dev/null 2>&1; then
        missing="curl $missing"
    fi

    # macOS doesn't need unzip from package manager
    OS="$(uname -s)"
    if [ "$OS" = "Linux" ]; then
        if ! command -v tar >/dev/null 2>&1; then
            missing="tar $missing"
        fi
        # Only need unzip if we somehow use zip on Linux (we use tar.gz, but just in case)
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

# Detect OS and architecture
detect_platform() {
    OS="$(uname -s)"
    case "$OS" in
        Linux*)  PLATFORM="unknown-linux-gnu" ;;
        Darwin*) PLATFORM="apple-darwin" ;;
        *)
            echo "ERROR: Unsupported OS: $OS"
            exit 1
            ;;
    esac

    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64|amd64)   ARCH="x86_64" ;;
        aarch64|arm64)  ARCH="aarch64" ;;
        *)
            echo "ERROR: Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    # Detect musl libc on Linux
    MUSL_SUFFIX=""
    if [ "$OS" = "Linux" ] && ldd /bin/ls 2>/dev/null | grep -q musl; then
        MUSL_SUFFIX="-musl"
    fi

    TARGET="${ARCH}-${PLATFORM}${MUSL_SUFFIX}"
}

# Resolve the version to install
resolve_version() {
    VERSION="${VERSION:-latest}"

    if [ "$VERSION" = "latest" ]; then
        echo "Fetching latest version from GitHub..."
        VERSION=$(curl -fsSL "https://api.github.com/repos/XiaomiMiMo/MiMo-Code/releases/latest" 2>/dev/null \
            | grep '"tag_name"' \
            | sed -E 's/.*"v?([^"]+)".*/\1/')
        if [ -z "$VERSION" ]; then
            echo "ERROR: Failed to determine latest version from GitHub API"
            exit 1
        fi
    fi

    echo "Installing MiMo Code version: ${VERSION}"
}

# Download and install the binary
download_and_install() {
    # Determine archive extension
    if [ "$(uname -s)" = "Darwin" ]; then
        EXT="zip"
    else
        EXT="tar.gz"
    fi

    DOWNLOAD_URL="https://github.com/XiaomiMiMo/MiMo-Code/releases/download/v${VERSION}/mimocode-${TARGET}.${EXT}"

    # Determine install directory
    if [ -n "${_REMOTE_USER_HOME:-}" ]; then
        INSTALL_DIR="${_REMOTE_USER_HOME}/.mimocode/bin"
    else
        INSTALL_DIR="${HOME}/.mimocode/bin"
    fi

    echo "Installing to: ${INSTALL_DIR}"
    mkdir -p "$INSTALL_DIR"

    # Download
    TMPDIR=$(mktemp -d)
    ARCHIVE="${TMPDIR}/mimocode.${EXT}"
    echo "Downloading from: ${DOWNLOAD_URL}"
    curl -fsSL "$DOWNLOAD_URL" -o "$ARCHIVE"

    # Extract
    if [ "$EXT" = "zip" ]; then
        unzip -o -q "$ARCHIVE" -d "$TMPDIR"
    else
        tar -xzf "$ARCHIVE" -C "$TMPDIR"
    fi

    # Find the mimo binary
    BINARY=$(find "$TMPDIR" -name "mimo" -type f 2>/dev/null | head -n 1)
    if [ -z "$BINARY" ]; then
        echo "ERROR: Could not find mimo binary in downloaded archive"
        ls -la "$TMPDIR"
        rm -rf "$TMPDIR"
        exit 1
    fi

    cp "$BINARY" "${INSTALL_DIR}/mimo"
    chmod +x "${INSTALL_DIR}/mimo"
    rm -rf "$TMPDIR"

    # Symlink to /usr/local/bin so it's on PATH
    ln -sf "${INSTALL_DIR}/mimo" /usr/local/bin/mimo
}

# Configure PATH for the remote user's shell profiles
configure_path() {
    if [ -z "${_REMOTE_USER:-}" ] || [ -z "${_REMOTE_USER_HOME:-}" ]; then
        return
    fi

    # Ensure ownership is correct
    chown -R "$_REMOTE_USER" "${_REMOTE_USER_HOME}/.mimocode" 2>/dev/null || true
}

# Print error guidance
print_install_help() {
    cat <<EOF

ERROR: MiMo Code CLI installation failed!

Please check:
  - Your network connectivity (can you reach github.com?)
  - The version '${VERSION:-latest}' exists at:
    https://github.com/XiaomiMiMo/MiMo-Code/releases

To install manually, try:
  curl -fsSL https://mimo.xiaomi.com/install | bash

EOF
}

# Main
main() {
    echo "Activating feature 'mimo-code'"

    ensure_dependencies
    detect_platform
    resolve_version
    download_and_install
    configure_path

    if command -v mimo >/dev/null 2>&1; then
        echo "MiMo Code v${VERSION} installed successfully!"
        mimo --version
    else
        print_install_help
        exit 1
    fi
}

main
