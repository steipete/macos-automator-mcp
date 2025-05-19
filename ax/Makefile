# Makefile for ax Swift utility

# Variables
SWIFT_BUILD_DIR := .build/apple/Products/Release
UNIVERSAL_BINARY_NAME := ax
UNIVERSAL_BINARY_PATH := $(SWIFT_BUILD_DIR)/$(UNIVERSAL_BINARY_NAME)
FINAL_BINARY_PATH := $(CURDIR)/$(UNIVERSAL_BINARY_NAME)

# Default target
all: $(FINAL_BINARY_PATH)

# Build the universal binary, strip it, and place it in the ax/ directory
$(FINAL_BINARY_PATH): $(UNIVERSAL_BINARY_PATH)
	@echo "Copying stripped universal binary to $(FINAL_BINARY_PATH)"
	@cp $(UNIVERSAL_BINARY_PATH) $(FINAL_BINARY_PATH)
	@echo "Final binary ready at $(FINAL_BINARY_PATH)"

$(UNIVERSAL_BINARY_PATH):
	@echo "Building universal binary for $(UNIVERSAL_BINARY_NAME) (arm64 + x86_64) with size optimization (Osize, ThinLTO, dead_strip)..."
	@swift build -c release --arch arm64 --arch x86_64 -Xswiftc -Osize -Xswiftc -lto=llvm-thin -Xcc -Wl,-dead_strip
	@echo "Stripping symbols from $(UNIVERSAL_BINARY_PATH)..."
	@strip $(UNIVERSAL_BINARY_PATH)
	@echo "Universal binary built and stripped at $(UNIVERSAL_BINARY_PATH)"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf .build $(FINAL_BINARY_PATH)
	@echo "Clean complete."

.PHONY: all clean
