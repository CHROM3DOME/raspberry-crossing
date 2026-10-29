#!/bin/bash
# ==============================================================================
# OpenCrossing Port Launcher: Stable Production
# Target: Raspberry Pi Zero 2W / RetroPie
# ==============================================================================

# Locate game installation directory
if [ -d "/home/pi/AnimalCrossing" ]; then
    GAME_DIR="/home/pi/AnimalCrossing"
elif [ -d "$HOME/AnimalCrossing" ]; then
    GAME_DIR="$HOME/AnimalCrossing"
elif [ -f "$(dirname "$0")/AnimalCrossing" ]; then
    GAME_DIR="$(dirname "$0")"
elif [ -f "$(dirname "$0")/../AnimalCrossing" ]; then
    GAME_DIR="$(dirname "$0")/.."
else
    GAME_DIR="$(pwd)"
fi

cd "$GAME_DIR" || exit 1

# Clear any active recording / benchmark flags
unset AC_RECORD AC_BENCHMARK

# Guarantee EmulationStation unfreezing on normal exit, error, or signal
trap 'killall -CONT emulationstation emulationstatio 2>/dev/null || true' EXIT INT TERM HUP

# Freeze EmulationStation to prevent background CPU cycles
killall -STOP emulationstation emulationstatio 2>/dev/null || true

# VideoCore IV DispmanX & ALSA Audio configuration
# DispmanX Layer 10010 ensures rendering sits atop EmulationStation (layer 10000)
export SDL_VIDEODRIVER=rpi
export SDL_RPI_VIDEO_LAYER=10010
export SDL_AUDIODRIVER=alsa

# Production launch: clean execution, pure human controller play
./AnimalCrossing "$@" > "$GAME_DIR/game.log" 2>&1

# Resume EmulationStation upon exit
killall -CONT emulationstation emulationstatio 2>/dev/null || true
