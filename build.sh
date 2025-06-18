#!/bin/bash

swift build \
  --configuration release \
  --triple riscv32imac-unknown-none-elf \
  --toolset toolset.json
