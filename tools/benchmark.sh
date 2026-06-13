#!/usr/bin/env bash
# Deterministic release benchmark launcher.
#
# Export a release build, then run:
#   BENCHMARK_BIN=/path/to/game tools/benchmark.sh
#
# For harness development only:
#   tools/benchmark.sh --editor --frames 120 --warmup 30
#
# A/B example:
#   tools/benchmark.sh --without shadows,post-processing
set -euo pipefail
cd "$(dirname "$0")/.."

BENCHMARK_BIN="${BENCHMARK_BIN:-}"
USE_EDITOR=0
DISABLED="${BENCHMARK_DISABLED:-}"
QUALITY="${BENCHMARK_QUALITY:-medium}"
AA_MODE="${BENCHMARK_AA:-taa}"
RESOLUTION="${BENCHMARK_RESOLUTION:-1920x1080}"
TIME_OF_DAY="${BENCHMARK_TIME_OF_DAY:-17.5}"
WARMUP="${BENCHMARK_WARMUP:-180}"
FRAMES="${BENCHMARK_FRAMES:-900}"
OUTPUT="${BENCHMARK_OUTPUT:-/tmp/gta_caliber_benchmark.md}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --bin)
            BENCHMARK_BIN="$2"
            shift 2
            ;;
        --editor)
            USE_EDITOR=1
            shift
            ;;
        --without)
            DISABLED="$2"
            shift 2
            ;;
        --quality)
            QUALITY="$2"
            shift 2
            ;;
        --aa)
            AA_MODE="$2"
            shift 2
            ;;
        --resolution)
            RESOLUTION="$2"
            shift 2
            ;;
        --time-of-day)
            TIME_OF_DAY="$2"
            shift 2
            ;;
        --warmup)
            WARMUP="$2"
            shift 2
            ;;
        --frames)
            FRAMES="$2"
            shift 2
            ;;
        --output)
            OUTPUT="$2"
            shift 2
            ;;
        *)
            echo "error: unknown option '$1'" >&2
            exit 2
            ;;
    esac
done

ARGS=(--resolution "$RESOLUTION" -- --benchmark)
REQUIRE_RELEASE=1
if [[ "$USE_EDITOR" == 1 ]]; then
    BENCHMARK_BIN="${GODOT:-godot}"
    if ! command -v "$BENCHMARK_BIN" >/dev/null 2>&1; then
        if [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
            BENCHMARK_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
        else
            echo "error: Godot not found; set GODOT=/path/to/godot" >&2
            exit 1
        fi
    fi
    ARGS=(--path game "${ARGS[@]}")
    REQUIRE_RELEASE=0
elif [[ -z "$BENCHMARK_BIN" || ! -x "$BENCHMARK_BIN" ]]; then
    echo "error: set BENCHMARK_BIN to an executable release export (or pass --editor)" >&2
    exit 1
fi

COMMIT="$(git rev-parse HEAD)"
COMMAND="$BENCHMARK_BIN ${ARGS[*]}"

env \
    BENCHMARK_REQUIRE_RELEASE="$REQUIRE_RELEASE" \
    BENCHMARK_COMMIT="$COMMIT" \
    BENCHMARK_COMMAND="$COMMAND" \
    BENCHMARK_DISABLED="$DISABLED" \
    BENCHMARK_QUALITY="$QUALITY" \
    BENCHMARK_AA="$AA_MODE" \
    BENCHMARK_RESOLUTION="$RESOLUTION" \
    BENCHMARK_TIME_OF_DAY="$TIME_OF_DAY" \
    BENCHMARK_WARMUP="$WARMUP" \
    BENCHMARK_FRAMES="$FRAMES" \
    BENCHMARK_OUTPUT="$OUTPUT" \
    GTA_QUALITY="$QUALITY" \
    "$BENCHMARK_BIN" "${ARGS[@]}"
