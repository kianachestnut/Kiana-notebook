#!/bin/bash
# One-click Miniconda installation script for zzsun user

echo "======================================================================"
echo "Miniconda Installation Script"
echo "======================================================================"

# Clean up old installation
echo ""
echo "Step 1: Cleaning up old installation..."
rm -rf /home/zzsun/miniconda3
rm -rf ~/.conda
rm -rf ~/.condarc
echo "✓ Cleanup complete"

# Download installer
echo ""
echo "Step 2: Downloading Miniconda installer..."
cd ~

# Try to download
if ! wget -q https://repo.anaconda.com/miniconda/Miniconda3-py38_4.12.0-Linux-x86_64.sh; then
    echo "Main site failed, trying mirror..."
    wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-py38_4.12.0-Linux-x86_64.sh
fi

if [ ! -f "Miniconda3-py38_4.12.0-Linux-x86_64.sh" ]; then
    echo "✗ Download failed!"
    exit 1
fi
echo "✓ Download complete"

# Install in batch mode
echo ""
echo "Step 3: Installing Miniconda..."
bash Miniconda3-py38_4.12.0-Linux-x86_64.sh -b -p /home/zzsun/miniconda3

if [ $? -ne 0 ]; then
    echo "✗ Installation failed!"
    exit 1
fi
echo "✓ Installation complete"

# Initialize
echo ""
echo "Step 4: Initializing conda..."
/home/zzsun/miniconda3/bin/conda init bash
source ~/.bashrc
echo "✓ Initialization complete"

# Verify
echo ""
echo "Step 5: Verifying installation..."
if command -v conda &> /dev/null; then
    echo "✓ Conda installed successfully!"
    conda --version
else
    echo "✗ Conda command not found. Please run: source ~/.bashrc"
fi

# Clean up installer
echo ""
echo "Step 6: Cleaning up..."
rm Miniconda3-py38_4.12.0-Linux-x86_64.sh
echo "✓ Cleanup complete"

echo ""
echo "======================================================================"
echo "Installation Complete!"
echo "======================================================================"
echo ""
echo "Next steps:"
echo "  1. Close and reopen your terminal, or run: source ~/.bashrc"
echo "  2. Verify: conda --version"
echo "  3. Create analysis environment:"
echo "     conda create -n cesm_analysis python=3.8 -y"
echo "     conda activate cesm_analysis"
echo "     conda install -c conda-forge netcdf4 xarray numpy matplotlib cartopy -y"
echo ""
