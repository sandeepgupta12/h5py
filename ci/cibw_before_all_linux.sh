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
    
    # Check if we're in a container or on a self-hosted runner
    if [[ -f /.dockerenv ]] || [[ "$container" == "docker" ]]; then
        echo "Running in container environment"
        # Container setup - Python should already be available
    else
        echo "Running on self-hosted runner - checking Python installation"
        
        # Check if Python 3.12 is available, if not install it
        if ! command -v python3.12 &> /dev/null; then
            echo "Installing Python 3.12..."
            
            # Detect package manager and install Python
            if command -v apt-get &> /dev/null; then
                sudo apt-get update
                sudo apt-get install -y python3.12 python3.12-dev python3.12-venv python3.12-pip
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y python3.12 python3.12-devel python3.12-pip
            elif command -v yum &> /dev/null; then
                sudo yum install -y python3.12 python3.12-devel python3.12-pip
            else
                echo "Warning: No supported package manager found. Python 3.12 might not be available."
            fi
        fi
        
        # Set up Python alternatives if needed
        if [[ ! -L /usr/bin/python3 ]] || [[ "$(readlink /usr/bin/python3)" != "/usr/bin/python3.12" ]]; then
            echo "Setting up Python alternatives..."
            sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 || true
            sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 || true
        fi
    fi
    
    # Verify Python is working
    python3 --version
    
    echo "ppc64le environment setup complete"
fi

# Common Linux setup for all architectures
echo "Common Linux setup complete"