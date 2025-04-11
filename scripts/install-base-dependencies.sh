#!/bin/bash

persistent_env_name=$1
persistent_env_path=$2

# Function to check if conda is installed
check_conda() {
    if ! command -v conda &> /dev/null; then
        echo "Error: conda is not installed or not in PATH."
        exit 1
    fi
}

# Function to install CUDA packages
install_cuda_packages() {
    echo "Checking for existing cudatoolkit 11..."
    if conda list --name $persistent_env_name | grep -q "cudatoolkit.*11\."; then
        echo "Found cudatoolkit 11, uninstalling..."
        conda uninstall -y --name $persistent_env_name cudatoolkit
        if [ $? -ne 0 ]; then
            echo "Error: Failed to uninstall cudatoolkit 11."
            exit 1
        fi
        echo "cudatoolkit 11 uninstalled successfully."
    else
        echo "cudatoolkit 11 not found, proceeding with installation."
    fi
    
    echo "Installing CUDA packages..."
    conda install -y -c conda-forge --name $persistent_env_name cuda-version=12.4 cuda-nvcc=12.4 cuda-nvrtc=12.4 cuda-runtime=12.4
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install CUDA packages."
        exit 1
    fi
    
    echo "CUDA packages installed successfully."
}

# Function to update .bashrc
update_mamba_env() {
    # Check if .bashrc exists
    if [ ! -f ~/.bashrc ]; then
        echo "Error: ~/.bashrc file not found."
        return 1
    fi
    echo "Updating mamba environment to $persistent_env_name in ~/.bashrc..."
    
    # Create a backup of the original file
    cp ~/.bashrc ~/.bashrc.bak
    
    # Check if the pattern exists in the file
    if grep -q "^mamba activate" ~/.bashrc; then
        # Replace the line starting with "mamba activate" with the new command
        sed -i "s/^mamba activate.*/mamba activate $persistent_env_name/" ~/.bashrc
        echo "Successfully updated mamba environment to $persistent_env_name/ in ~/.bashrc"
    else
        echo "No 'mamba activate' command found in ~/.bashrc"
    fi
}

# Function to update virtual environment activate script
update_venv_activate() {
    # Get the repository root (assuming the script is in scripts/ directory)
    local repo_root="$(cd "$(dirname "$0")/.." && pwd)"
    local activate_script="${repo_root}/.venv/bin/activate"

    # Check if the activate script exists
    if [ ! -f "$activate_script" ]; then
        echo "Warning: Virtual environment activate script not found at ${activate_script}"
        return 1
    fi
    
    echo "Checking if CUDA_PATH is already set in venv activate script..."
    
    if grep -q "export CUDA_PATH=" "$activate_script"; then
        echo "CUDA_PATH is already set in venv activate script."
    else
        echo "Adding CUDA_PATH to venv activate script..."
        echo "# Set CUDA_PATH for this virtual environment" >> "$activate_script"
        echo "export CUDA_PATH=$persistent_env_path" >> "$activate_script"
        echo "Added CUDA_PATH to venv activate script."
    fi
}

# Main function
main() {
    echo "Starting CUDA installation script..."

    # Assign the arguments to variables
    echo "Installing base dependencies in $persistent_env_name in location $persistent_env_path"
    
    # Check if conda is installed
    check_conda
    
    # # Install CUDA packages
    install_cuda_packages
    
    # Update .bashrc
    update_mamba_env

    # Update virtual environment activate script
    update_venv_activate
    
    echo "Installation complete. Please restart your shell or run 'source ~/.bashrc' to apply changes to this terminal."
}

# Run the main function
main