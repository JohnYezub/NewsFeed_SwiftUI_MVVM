#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/swift-paths.sh

if ! command -v swiftlint >/dev/null 2>&1; then
    echo "SwiftLint is required. Install it with: brew install swiftlint" >&2
    exit 1
fi

# SwiftLint reads the same directories from `included` in .swiftlint.yml.
swiftlint lint --strict --no-cache --config .swiftlint.yml
xcrun swift format lint --strict --configuration .swift-format --recursive "${SWIFT_PATHS[@]}"
