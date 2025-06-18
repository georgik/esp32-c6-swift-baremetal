#!/bin/bash
set -e

# Paths
REPOROOT=$(git rev-parse --show-toplevel)
TOOLSET="${REPOROOT}/toolset.json"
LLVM_OBJCOPY="llvm-objcopy"
SWIFT_BUILD="swift build"

# Build flags
SWIFT_BUILD_ARGS=(
  --configuration release
  --triple riscv32imac-unknown-none-elf
  --toolset "$TOOLSET"
  --disable-local-rpath
)

# Compute output directory
BUILDROOT=$($SWIFT_BUILD "${SWIFT_BUILD_ARGS[@]}" --show-bin-path)

# Build
echo "Building..."
$SWIFT_BUILD "${SWIFT_BUILD_ARGS[@]}" --verbose

# Extract binary
echo "Extracting binary..."
$LLVM_OBJCOPY -O binary \
  "${BUILDROOT}/MainApp" \
  "${BUILDROOT}/MainApp.bin"
