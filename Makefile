# Paths
REPOROOT         := $(shell git rev-parse --show-toplevel)
TOOLSROOT        := $(REPOROOT)/Tools
TOOLSET          := $(TOOLSROOT)/Toolsets/esp32-c6-elf.json
LLVM_OBJCOPY     := llvm-objcopy
SWIFT_BUILD      := swift build
ESP_FLASH 		 := espflash
LINKERSCRIPT_DIR := $(REPOROOT)/Sources/Support

# Flags
ARCH             := riscv32
TARGET           := $(ARCH)-none-none-eabi
SWIFT_BUILD_ARGS := \
    --configuration release \
    --triple $(TARGET) \
    --toolset $(TOOLSET) \
    --disable-local-rpath

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
	@echo "generating esp32 flash image using espflash..."
	$(ESP_FLASH) save-image \
		--chip esp32c6 \
		--flash-mode dio \
		--flash-size 4mb \
		--skip-padding \
		--merge \
		"$(BUILDROOT)/Application" \
		"$(BUILDROOT)/Application_flash.bin" \
		--bootloader Tools/Partitions/bootloader.bin \
		--partition-table Tools/Partitions/partition-table.bin \
		--partition-table-offset 0x8000

.PHONY: check-image
check-image:
	@echo "Inspecting ESP32 flash image..."
	$(ESP_IMAGE_TOOL) image_info "$(BUILDROOT)/Application_flash.bin"

.PHONY: flash
flash:
	@echo "flashing with espflash..."
	$(ESP_FLASH) flash \
		--chip esp32c6 \
		--baud $(FLASH_BAUD) \
		--before default-reset \
		--after hard-reset \
		--flash-mode dio \
		--flash-size 4mb \
		--bootloader Tools/Partitions/bootloader.bin \
		--partition-table Tools/Partitions/partition-table.bin \
		--partition-table-offset 0x8000 \
		"$(BUILDROOT)/Application"

.PHONY: image_info
image_info:
	@echo ""
	@echo "=== Hexdump header =="
	hexdump -C "$(BUILDROOT)/Application_flash.bin" | grep -n "32 54 cd ab"
	@echo ""
	@echo "=== FLASH IMAGE info ==="
	$(ESP_IMAGE_TOOL) image_info "$(BUILDROOT)/Application_flash.bin"
	@echo ""
	@echo "=== ELF sections ==="
	riscv32-unknown-elf-objdump -h "$(BUILDROOT)/Application"
