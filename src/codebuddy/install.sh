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

    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        missing="curl $missing"
    fi

    OS="$(uname -s)"
    if [ "$OS" = "Linux" ]; then
        if ! command -v tar >/dev/null 2>&1; then
            missing="tar $missing"
        fi
    fi

    if ! command -v shasum >/dev/null 2>&1 && ! command -v sha256sum >/dev/null 2>&1; then
        missing="sha256sum $missing"
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

# Detect OS and architecture
# CodeBuddy release artifact naming: codebuddy-code-{os}_{arch}.{ext}
# Examples: codebuddy-code_Linux_x86_64.tar.gz, codebuddy-code_Linux_aarch64.tar.gz,
#           codebuddy-code_Linux_x86_64_musl.tar.gz, codebuddy-code_Darwin_arm64.tar.gz
detect_platform() {
    OS="$(uname -s)"
    case "$OS" in
        Linux*)  PLATFORM="Linux" ;;
        Darwin*) PLATFORM="Darwin" ;;
        *)
            echo "ERROR: Unsupported OS: $OS"
            exit 1
            ;;
    esac

    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64|amd64)  ARCH="x86_64" ;;
        aarch64|arm64) ARCH="aarch64" ;;
        *)
            echo "ERROR: Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    # Detect musl libc on Linux
    MUSL_SUFFIX=""
    if [ "$OS" = "Linux" ]; then
        if [ -f /lib/libc.musl-x86_64.so.1 ] || \
           [ -f /lib/libc.musl-aarch64.so.1 ] || \
           ldd /bin/ls 2>&1 | grep -q musl; then
            MUSL_SUFFIX="_musl"
        fi
    fi

    TARGET="${PLATFORM}_${ARCH}${MUSL_SUFFIX}"
    EXT="tar.gz"
}

# Resolve the version to install
resolve_version() {
    VERSION="${VERSION:-latest}"

    if [ "$VERSION" = "latest" ]; then
        echo "Fetching latest version..."
        REPOSITORY="https://acc-1258344699.cos.accelerate.myqcloud.com/@tencent-ai/codebuddy-code/releases"
        VERSION=$(download "$REPOSITORY/latest" - 2>/dev/null | tr -d '[:space:]')
        if [ -z "$VERSION" ]; then
            echo "ERROR: Failed to determine latest version"
            exit 1
        fi
        # Version from API has no 'v' prefix
    fi

    echo "Installing CodeBuddy Code version: ${VERSION}"
}

# Verify checksum
verify_checksum() {
    local file=$1 expected=$2 actual

    if command -v shasum >/dev/null 2>&1; then
        actual=$(shasum -a 256 "$file" | awk '{print $1}')
    elif command -v sha256sum >/dev/null 2>&1; then
        actual=$(sha256sum "$file" | awk '{print $1}')
    else
        echo "WARNING: No checksum tool available, skipping verification"
        return 0
    fi

    if [ "$actual" != "$expected" ]; then
        echo "ERROR: Checksum verification failed!"
        echo "Expected: $expected"
        echo "Actual:   $actual"
        exit 1
    fi
    echo "Checksum verified: $expected"
}

# Download and install the binary
download_and_install() {
    REPOSITORY="https://acc-1258344699.cos.accelerate.myqcloud.com/@tencent-ai/codebuddy-code/releases"
    ARCHIVE_NAME="codebuddy-code_${TARGET}.${EXT}"
    DOWNLOAD_URL="$REPOSITORY/download/${VERSION}/${ARCHIVE_NAME}"

    # Determine install directory
    if [ -n "${_REMOTE_USER_HOME:-}" ]; then
        INSTALL_DIR="${_REMOTE_USER_HOME}/.codebuddy/bin"
    else
        INSTALL_DIR="${HOME}/.codebuddy/bin"
    fi

    echo "Installing to: ${INSTALL_DIR}"
    mkdir -p "$INSTALL_DIR"

    # Download
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT
    ARCHIVE="${TMPDIR}/codebuddy-code.${EXT}"
    echo "Downloading from: ${DOWNLOAD_URL}"
    download "$DOWNLOAD_URL" "$ARCHIVE"

    # Verify checksum
    echo "Verifying checksum..."
    CHECKSUMS=$(download "$REPOSITORY/download/${VERSION}/checksums.txt" "${TMPDIR}/checksums.txt" 2>/dev/null || true)
    if [ -f "${TMPDIR}/checksums.txt" ] && [ -s "${TMPDIR}/checksums.txt" ]; then
        expected=$(grep " ${ARCHIVE_NAME}$" "${TMPDIR}/checksums.txt" | awk '{print $1}')
        if [ -n "$expected" ]; then
            verify_checksum "$ARCHIVE" "$expected"
        else
            echo "WARNING: Checksum not found for $ARCHIVE_NAME, skipping verification"
        fi
    else
        echo "WARNING: Could not download checksums, skipping verification"
    fi

    # Extract
    tar -xzf "$ARCHIVE" -C "$TMPDIR"

    # Find the codebuddy binary
    BINARY=$(find "$TMPDIR" -name "codebuddy" -type f 2>/dev/null | head -n 1)
    if [ -z "$BINARY" ]; then
        echo "ERROR: Could not find codebuddy binary in downloaded archive"
        ls -la "$TMPDIR"
        exit 1
    fi

    cp "$BINARY" "${INSTALL_DIR}/codebuddy"
    chmod +x "${INSTALL_DIR}/codebuddy"

    # Symlink to /usr/local/bin so it's on PATH
    ln -sf "${INSTALL_DIR}/codebuddy" /usr/local/bin/codebuddy
}

# Fix ownership for remote user
configure_ownership() {
    if [ -z "${_REMOTE_USER:-}" ] || [ -z "${_REMOTE_USER_HOME:-}" ]; then
        return
    fi

    chown -R "$_REMOTE_USER" "${_REMOTE_USER_HOME}/.codebuddy" 2>/dev/null || true
}

# Print error guidance
print_install_help() {
    cat <<EOF

ERROR: CodeBuddy Code CLI installation failed!

Please check:
  - Your network connectivity
  - The version '${VERSION:-latest}' exists

To install manually, try:
  curl -fsSL https://www.codebuddy.cn/cli/install.sh | bash

EOF
}

# Main
main() {
    echo "Activating feature 'codebuddy'"

    ensure_dependencies
    detect_platform
    resolve_version
    download_and_install
    configure_ownership

    if command -v codebuddy >/dev/null 2>&1; then
        echo "CodeBuddy Code v${VERSION} installed successfully!"
        codebuddy --version
    else
        print_install_help
        exit 1
    fi
}

main
