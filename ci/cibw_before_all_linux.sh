#!/bin/bash
set -euo pipefail

# This script sets up the environment for Linux builds, particularly for ppc64le
# It handles Python installation and setup for architectures that might not have
# Python pre-installed or properly configured

WORKSPACE_DIR=$1
ARCH=${CIBW_ARCHS:-$(uname -m)}

echo "Setting up Linux environment for architecture: $ARCH"
echo "Workspace directory: $WORKSPACE_DIR"

# For ppc64le and other architectures that might need Python setup
if [[ "$ARCH" == "ppc64le" ]]; then
    echo "Setting up ppc64le environment..."
    
    # For ppc64le, always ensure Python is properly set up regardless of environment
    echo "Ensuring Python is available and properly configured..."
    
    # Check if Python 3.12 is available, if not try to install it
    if ! command -v python3.12 &> /dev/null; then
        echo "Python 3.12 not found, attempting to install..."
        
        # Detect package manager and install Python
        if command -v apt-get &> /dev/null; then
            apt-get update || sudo apt-get update
            apt-get install -y python3.12 python3.12-dev python3.12-venv python3.12-pip || \
                sudo apt-get install -y python3.12 python3.12-dev python3.12-venv python3.12-pip
        elif command -v dnf &> /dev/null; then
            dnf install -y python3.12 python3.12-devel python3.12-pip || \
                sudo dnf install -y python3.12 python3.12-devel python3.12-pip
        elif command -v yum &> /dev/null; then
            yum install -y python3.12 python3.12-devel python3.12-pip || \
                sudo yum install -y python3.12 python3.12-devel python3.12-pip
        else
            echo "Warning: No supported package manager found. Python 3.12 might not be available."
        fi
    fi
    
    # Set up Python alternatives if needed (whether in container or not)
    if command -v update-alternatives &> /dev/null; then
        # Try without sudo first, then with sudo if needed
        update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 2>/dev/null || \
            sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 2>/dev/null || true
        update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 2>/dev/null || \
            sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 2>/dev/null || true
    fi
    
    # Create symlinks as fallback
    if [[ ! -L /usr/bin/python3 ]] || [[ "$(readlink /usr/bin/python3)" != "/usr/bin/python3.12" ]]; then
        ln -sf /usr/bin/python3.12 /usr/bin/python3 2>/dev/null || \
            sudo ln -sf /usr/bin/python3.12 /usr/bin/python3 2>/dev/null || true
    fi
    if [[ ! -L /usr/bin/python ]] || [[ "$(readlink /usr/bin/python)" != "/usr/bin/python3.12" ]]; then
        ln -sf /usr/bin/python3.12 /usr/bin/python 2>/dev/null || \
            sudo ln -sf /usr/bin/python3.12 /usr/bin/python 2>/dev/null || true
    fi
    
    # Verify Python is working
    python3 --version
    
    # Export environment variables for cibuildwheel
    export PYTHON=/usr/bin/python3
    export PYTHONPATH=${PYTHONPATH:-}
    export PATH="/usr/bin:/usr/local/bin:$PATH"
    
    # Set GitHub environment variables if running in GitHub Actions
    if [[ -n "$GITHUB_ENV" ]]; then
        echo "PYTHON=/usr/bin/python3" >> "$GITHUB_ENV"
        echo "PATH=/usr/bin:/usr/local/bin:$PATH" >> "$GITHUB_ENV"
    fi
    
    echo "ppc64le environment setup complete"
fi

# Common Linux setup for all architectures
echo "Common Linux setup complete"