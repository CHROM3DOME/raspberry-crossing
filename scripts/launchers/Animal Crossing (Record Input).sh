#!/bin/bash
# ==============================================================================
# OpenCrossing Port Launcher: Record Input (Benchmark Macro Generation)
# Target: Raspberry Pi Zero 2W / RetroPie
# ==============================================================================

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

# Guarantee EmulationStation unfreezing on normal exit, error, or signal
trap 'killall -CONT emulationstation emulationstatio 2>/dev/null || true' EXIT INT TERM HUP

# Freeze EmulationStation
killall -STOP emulationstation emulationstatio 2>/dev/null || true

export SDL_VIDEODRIVER=rpi
export SDL_RPI_VIDEO_LAYER=10010
export SDL_AUDIODRIVER=alsa

# Record active controller button presses and analog stick positions
export AC_RECORD="$GAME_DIR/inputs_recorded.acrec"
unset AC_BENCHMARK

./AnimalCrossing "$@" > "$GAME_DIR/record.log" 2>&1

# Resume EmulationStation upon exit
killall -CONT emulationstation emulationstatio 2>/dev/null || true
