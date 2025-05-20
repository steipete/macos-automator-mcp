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
	@echo "Building universal binary for $(UNIVERSAL_BINARY_NAME) (arm64 + x86_64) with size optimization (Osize, dead_strip)..."
	@swift build -c release --arch arm64 --arch x86_64 -Xswiftc -Osize -Xlinker -Wl,-dead_strip
	@echo "Aggressively stripping symbols (strip -x) from $(UNIVERSAL_BINARY_PATH)..."
	@strip -x $(UNIVERSAL_BINARY_PATH)
	@echo "Universal binary built and stripped: $(UNIVERSAL_BINARY_PATH)"

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(SWIFT_BUILD_DIR)
	@rm -f $(FINAL_BINARY_PATH)
	@rm -f $(UNIVERSAL_BINARY_PATH) # Also remove the intermediate universal binary if it exists
	@echo "Clean complete."

.PHONY: all clean
