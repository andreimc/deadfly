#!/usr/bin/env sh
set -u

INSTALL_DIR="${1:-/usr/local/bin}"

DEADFLY_ROOT="https://github.com/andreimc/deadfly/releases/download"

DEADFLY_VERS="0.0.2"

expand() {
    case "$1" in
    (\~)        echo "$HOME";;
    (\~/*)      echo "$HOME/${1#\~/}";;
    (\~[^/]*/*) local user=$(eval echo ${1%%/*}) && echo "$user/${1#*/}";;
    (\~[^/]*)   eval echo ${1};;
    (*)         echo "$1";;
    esac
}

install() {

    # Check for necessary commands

    command -v uname >/dev/null 2>&1 || {
        err "Error: you need to have 'uname' installed and in your path"
    }

    command -v mkdir >/dev/null 2>&1 || {
        err "Error: you need to have 'mkdir' installed and in your path"
    }

    command -v read >/dev/null 2>&1 || {
        err "Error: you need to have 'read' installed and in your path"
    }

    command -v tar >/dev/null 2>&1 || {
        err "Error: you need to have 'tar' installed and in your path"
    }

    # Check for curl or wget commands

    local _cmd

    if command -v curl >/dev/null 2>&1; then
        _cmd=curl
    elif command -v wget >/dev/null 2>&1; then
        _cmd=wget
    else
        err "Error: you need to have 'curl' or 'wget' installed and in your path"
    fi

    # Fetch the latest deadfly version

    echo "Fetching the latest database version..."

    local _ver=$DEADFLY_VERS
    
    # if [ "$NIGHTLY" = true ]; then
        
    #     _ver="nightly"
    
    # else

    #     if [ "$_cmd" = curl ]; then
    #         _ver=$(curl --silent --fail --location "$DEADFLY_VERS") || {
    #             err "Error: could not fetch the latest deadfly version number"
    #         }
    #     elif [ "$_cmd" = wget ]; then
    #         _ver=$(wget --quiet "$DEADFLY_VERS") || {
    #             err "Error: could not fetch the latest deadfly version number"
    #         }
    #     fi
        
    # fi

    # Compute the current system architecture

    echo "Fetching the host system architecture..."

    local _oss
    local _cpu
    local _arc

    _oss="$(uname -s)"
    _cpu="$(uname -m)"

    case "$_oss" in
        Linux) _oss=linux;;
        Darwin) _oss=darwin;;
        MINGW* | MSYS* | CYGWIN*) _oss=windows;;
        *) err "Error: unsupported operating system: $_oss";;
    esac

    case "$_cpu" in
        arm64 | aarch64) _cpu=arm64;;
        x86_64 | x86-64 | x64 | amd64) _cpu=amd64;;
        *) err "Error: unsupported CPU architecture: $_cpu";;
    esac

    _arc="${_oss}-${_cpu}"

    # Compute the download file extension type

    local _ext

    case "$_oss" in
        linux) _ext="tar.gz";;
        darwin) _ext="tar.gz";;
        windows) _ext="zip";;
    esac

    # Define the latest deadfly download url

    local _url

    _url="${DEADFLY_ROOT}/${_ver}/deadfly-${_ver}-${_arc}.${_ext}"
    
    # Download and unarchive the latest deadfly binary

    cd /tmp

    echo "Installing deadfly-${_ver} for ${_arc}..."

    if [ "$_cmd" = curl ]; then
        curl --silent --fail --location "$_url" --output "deadfly-${_ver}-${_arc}.${_ext}" || {
            err "Error: could not fetch the latest deadfly file"
        }
    elif [ "$_cmd" = wget ]; then
        wget --quiet "$_url" -O "deadfly-${_ver}-${_arc}.${_ext}" || {
            err "Error: could not fetch the latest deadfly file"
        }
    fi

    tar -zxf "deadfly-${_ver}-${_arc}.${_ext}" || {
        err "Error: unable to extract the downloaded archive file"
    }

    # Install the deadfly binary into the specified directory

    local _loc="$INSTALL_DIR"
        
    mkdir -p "$_loc" 2>/dev/null
    
    if [ ! -d "$_loc" ] || ! touch "$_loc/deadfly" 2>/dev/null; then
        echo ""
        read -p "Where would you like to install the 'deadfly' binary [~/.deadfly]? " _loc
        _loc=${_loc:-~/.deadfly} && _loc=$(expand "$_loc")
        mkdir -p "$_loc"
    fi
        
    mv "deadfly" "$_loc" 2>/dev/null || {
        err "Error: we couldn't install the 'deadfly' binary into $_loc"
    }
    
    # Show some simple instructions

    echo ""    
    echo "deadfly successfully installed in:"
    echo "  ${_loc}/deadfly"
    echo ""

    if [ "${_loc}" != "${INSTALL_DIR}" ]; then
        echo "To ensure that deadfly is in your \$PATH run:"
        echo "  PATH=${_loc}:\$PATH"
        echo "Or to move the binary to ${INSTALL_DIR} run:"
        echo "  sudo mv ${_loc}/deadfly ${INSTALL_DIR}"
        echo ""
    fi

    echo "To see the command-line options run:"
    echo "  deadfly help"
    echo "To start an in-memory database server run:"
    echo "  deadfly start --log debug --user root --pass root memory"
    echo "For help with getting started visit:"
    echo "  https://deadfly.com/docs"
    echo ""

    # Exit cleanly

    exit 0

}

err() {
    echo "$1" >&2 && exit 1
}

install "$@" || exit 1