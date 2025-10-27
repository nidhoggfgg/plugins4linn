.PHONY: all clean build-go build-rust help

BUILD_DIR := build

# Find all Go and Rust projects
GO_PROJECTS := $(dir $(wildcard */main.go))
RUST_PROJECTS := $(dir $(wildcard */Cargo.toml))

all: build-go build-rust
	@echo "✓ All WASM plugins built successfully!"
	@echo "Output directory: $(BUILD_DIR)/"

help:
	@echo "Available targets:"
	@echo "  make all         - Build all WASM plugins (Go + Rust)"
	@echo "  make build-go    - Build only Go plugins"
	@echo "  make build-rust  - Build only Rust plugins"
	@echo "  make clean       - Remove build directory"
	@echo "  make help        - Show this help message"

build-go:
	@echo "=== Building Go projects ==="
	@mkdir -p $(BUILD_DIR)
	@$(foreach dir,$(GO_PROJECTS), \
		echo "Building Go project: $(dir)"; \
		mkdir -p $(BUILD_DIR)/$(dir); \
		cd $(dir) && GOOS=wasip1 GOARCH=wasm go build -o ../$(BUILD_DIR)/$(dir)main.wasm . && cd .. || exit 1; \
	)

build-rust:
	@echo "=== Building Rust projects ==="
	@mkdir -p $(BUILD_DIR)
	@$(foreach dir,$(RUST_PROJECTS), \
		echo "Building Rust project: $(dir)"; \
		mkdir -p $(BUILD_DIR)/$(dir); \
		cd $(dir) && cargo build --release --target wasm32-wasip2 && \
		cp target/wasm32-wasip2/release/$(notdir $(dir:/=)).wasm ../$(BUILD_DIR)/$(dir)main.wasm 2>/dev/null || \
		cp target/wasm32-wasip2/release/$$(echo $(notdir $(dir:/=)) | tr '_' '-').wasm ../$(BUILD_DIR)/$(dir)main.wasm && \
		cd .. || exit 1; \
	)

clean:
	@echo "Cleaning build directory..."
	@rm -rf $(BUILD_DIR)
	@echo "✓ Clean complete!"

