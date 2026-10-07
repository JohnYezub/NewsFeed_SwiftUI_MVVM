#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/swift-paths.sh

xcrun swift format format --configuration .swift-format --in-place --recursive "${SWIFT_PATHS[@]}"
