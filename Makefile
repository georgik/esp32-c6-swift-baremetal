# Paths
REPOROOT         := $(shell git rev-parse --show-toplevel)
TOOLSROOT        := $(REPOROOT)/Tools
TOOLSET          := $(TOOLSROOT)/Toolsets/esp32-c6-elf.json
LLVM_OBJCOPY     := llvm-objcopy
SWIFT_BUILD      := swift build
ESP_IMAGE_TOOL := esptool.py
LINKERSCRIPT_DIR := $(REPOROOT)/Sources/Support

# Flags
ARCH             := riscv32
TARGET           := $(ARCH)-none-none-eabi
SWIFT_BUILD_ARGS := \
    --configuration release \
    --triple $(TARGET) \
    --toolset $(TOOLSET) \
    --disable-local-rpath \
    -Xswiftc -no-clang-module-breadcrumbs

BUILDROOT        := $(shell $(SWIFT_BUILD) $(SWIFT_BUILD_ARGS) --show-bin-path)
FLASH_BAUD       := 460800

.PHONY: build
build:
	@echo "building..."
	$(SWIFT_BUILD) \
		$(SWIFT_BUILD_ARGS) \
		--verbose

	@echo "extracting binary..."
	$(LLVM_OBJCOPY) \
		--only-section .text \
		--only-section .rodata \
		-O binary \
		"$(BUILDROOT)/Application" \
		"$(BUILDROOT)/Application.bin"


.PHONY: clean
clean:
	@echo "cleaning..."
	@swift package clean
	@rm -rf .build

.PHONY: elf2image
elf2image:
	@echo "generating esp32 flash image..."
	$(ESP_IMAGE_TOOL) --chip esp32c6 elf2image \
	    --flash_mode dio \
	    --flash_freq 80m \
	    --flash_size 2MB \
	    --output "$(BUILDROOT)/Application_flash.bin" \
	    "$(BUILDROOT)/Application"

.PHONY: check-image
check-image:
	@echo "Inspecting ESP32 flash image..."
	$(ESP_IMAGE_TOOL) image_info "$(BUILDROOT)/Application_flash.bin"

.PHONY: flash
flash:
	@echo "flashing..."
	esptool.py --chip esp32c6 \
	    -b $(FLASH_BAUD) \
	    --before=default_reset \
	    --after=hard_reset \
	    write_flash \
	    --flash_mode dio \
	    --flash_freq 80m \
	    --flash_size 2MB \
	    0x0     Tools/Partitions/bootloader.bin \
	    0x10000 $(BUILDROOT)/Application_flash.bin \
	    0x8000  Tools/Partitions/partition-table.bin

.PHONY: image_info
image_info:
	@echo ""
	@echo "=== FLASH IMAGE info ==="
	$(ESP_IMAGE_TOOL) image_info "$(BUILDROOT)/Application_flash.bin"
	@echo ""
	@echo "=== ELF sections ==="
	riscv32-unknown-elf-objdump -h "$(BUILDROOT)/Application"
