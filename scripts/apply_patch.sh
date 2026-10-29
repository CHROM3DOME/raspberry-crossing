#!/bin/bash
# ==============================================================================
# OpenCrossing Patch Application Helper for Raspberry Pi Zero 2W / Pi Tin
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PATCH_DIR="$RELEASE_ROOT/patches"
CONFIG_DIR="$RELEASE_ROOT/config"

GENERIC_PATCH="$PATCH_DIR/0001-opencrossing-rpi-zero2w-generic.patch"
PITIN_PATCH="$PATCH_DIR/0001-opencrossing-rpi-zero2w-pi-tin.patch"

BASE_COMMIT="762ea7a"
UPSTREAM_REPO="https://github.com/GabeConway/OpenCrossing-Anbernic.git"

echo "======================================================================"
echo " OpenCrossing - Raspberry Pi Zero 2W / Pi Tin Patch Applicator"
echo "======================================================================"
echo ""
echo "Select the target hardware variant:"
echo "  1) Generic Raspberry Pi Zero 2W (HDMI TV / Standard Gamepads)"
echo "  2) Pi Tin Handheld (2.8\" SPI LCD 320x240 / GPIOnext Controls)"
echo ""
read -r -p "Enter choice [1 or 2]: " CHOICE

case "$CHOICE" in
    1)
        TARGET_NAME="Generic Raspberry Pi Zero 2W"
        SELECTED_PATCH="$GENERIC_PATCH"
        SELECTED_CONFIG="$CONFIG_DIR/settings.ini.generic"
        ;;
    2)
        TARGET_NAME="Pi Tin Handheld"
        SELECTED_PATCH="$PITIN_PATCH"
        SELECTED_CONFIG="$CONFIG_DIR/settings.ini.pitin"
        ;;
    *)
        echo "Invalid selection. Exiting."
        exit 1
        ;;
esac

echo ""
echo "Target variant selected: $TARGET_NAME"
echo "Using patch: $(basename "$SELECTED_PATCH")"

if [ ! -f "$SELECTED_PATCH" ]; then
    echo "Error: Patch file not found at $SELECTED_PATCH"
    exit 1
fi

# Determine source directory
DEFAULT_SRC_DIR="$RELEASE_ROOT/OpenCrossing-source"
echo ""
read -r -p "Enter path to OpenCrossing source directory [default: $DEFAULT_SRC_DIR]: " USER_SRC_DIR
SRC_DIR="${USER_SRC_DIR:-$DEFAULT_SRC_DIR}"

if [ ! -d "$SRC_DIR" ]; then
    echo "Directory does not exist. Cloning upstream repository from $UPSTREAM_REPO..."
    git clone "$UPSTREAM_REPO" "$SRC_DIR"
    cd "$SRC_DIR"
    echo "Checking out base commit $BASE_COMMIT..."
    git checkout "$BASE_COMMIT"
else
    cd "$SRC_DIR"
    if [ -d ".git" ]; then
        echo "Verifying base commit in existing git repository..."
        git checkout "$BASE_COMMIT" || {
            echo "Warning: Could not checkout commit $BASE_COMMIT automatically."
            echo "Please ensure repository is clean and reset to $BASE_COMMIT."
        }
    else
        echo "Warning: $SRC_DIR is not a git repository. Attempting direct patch application..."
    fi
fi

echo ""
echo "Testing patch applicability..."
if git apply --check "$SELECTED_PATCH"; then
    echo "Applying patch..."
    git apply "$SELECTED_PATCH"
    echo "Patch applied successfully!"
else
    echo "Error: Patch does not apply cleanly to $SRC_DIR."
    echo "Please ensure the source repository is at commit $BASE_COMMIT."
    exit 1
fi

# Copy pre-tuned settings.ini into source
if [ -f "$SELECTED_CONFIG" ]; then
    cp "$SELECTED_CONFIG" "$SRC_DIR/pc/settings.ini"
    echo "Copied default configuration to $SRC_DIR/pc/settings.ini"
fi

echo ""
echo "======================================================================"
echo " OpenCrossing patched successfully for: $TARGET_NAME"
echo "======================================================================"
echo ""
echo "Next steps to compile:"
echo ""
echo "Option A: Native Build on Raspberry Pi (Raspberry Pi OS Buster/Bullseye)"
echo "  sudo apt-get install -y gcc g++ cmake make libsdl2-dev libgles2-mesa-dev ninja-build"
echo "  cd $SRC_DIR/pc"
echo "  mkdir -p build && cd build"
echo "  cmake .. -G Ninja -DPC_USE_GLES=ON -DCMAKE_C_FLAGS=\"-mcpu=cortex-a53 -mfpu=neon-vfpv4 -mfloat-abi=hard -O2\""
echo "  ninja"
echo ""
echo "Option B: Docker Cross-Compilation (Fast build on Linux/WSL/macOS)"
echo "  See instructions in README.md"
echo ""
