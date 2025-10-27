.PHONY: all clean build help examples

BUILD_DIR := build
EXAMPLES_DIR := examples

# Find root-level projects (not in examples/)
ROOT_GO_PROJECTS := $(filter-out $(EXAMPLES_DIR)/%,$(dir $(wildcard */main.go)))
ROOT_RUST_PROJECTS := $(filter-out $(EXAMPLES_DIR)/%,$(dir $(wildcard */Cargo.toml)))
ROOT_C_PROJECTS := $(filter-out $(EXAMPLES_DIR)/%,$(dir $(wildcard */main.c)))
ROOT_ZIG_PROJECTS := $(filter-out $(EXAMPLES_DIR)/%,$(dir $(wildcard */main.zig)))

# Find example projects
EXAMPLE_GO_PROJECTS := $(dir $(wildcard $(EXAMPLES_DIR)/*/main.go))
EXAMPLE_RUST_PROJECTS := $(dir $(wildcard $(EXAMPLES_DIR)/*/Cargo.toml))
EXAMPLE_C_PROJECTS := $(dir $(wildcard $(EXAMPLES_DIR)/*/main.c))
EXAMPLE_ZIG_PROJECTS := $(dir $(wildcard $(EXAMPLES_DIR)/*/main.zig))

# Extract project names
ROOT_GO_NAMES := $(foreach dir,$(ROOT_GO_PROJECTS),$(notdir $(dir:/=)))
ROOT_RUST_NAMES := $(foreach dir,$(ROOT_RUST_PROJECTS),$(notdir $(dir:/=)))
ROOT_C_NAMES := $(foreach dir,$(ROOT_C_PROJECTS),$(notdir $(dir:/=)))
ROOT_ZIG_NAMES := $(foreach dir,$(ROOT_ZIG_PROJECTS),$(notdir $(dir:/=)))

EXAMPLE_GO_NAMES := $(foreach dir,$(EXAMPLE_GO_PROJECTS),$(notdir $(dir:/=)))
EXAMPLE_RUST_NAMES := $(foreach dir,$(EXAMPLE_RUST_PROJECTS),$(notdir $(dir:/=)))
EXAMPLE_C_NAMES := $(foreach dir,$(EXAMPLE_C_PROJECTS),$(notdir $(dir:/=)))
EXAMPLE_ZIG_NAMES := $(foreach dir,$(EXAMPLE_ZIG_PROJECTS),$(notdir $(dir:/=)))

ALL_ROOT_NAMES := $(ROOT_GO_NAMES) $(ROOT_RUST_NAMES) $(ROOT_C_NAMES) $(ROOT_ZIG_NAMES)
ALL_EXAMPLE_NAMES := $(addprefix $(EXAMPLES_DIR)/,$(EXAMPLE_GO_NAMES) $(EXAMPLE_RUST_NAMES) $(EXAMPLE_C_NAMES) $(EXAMPLE_ZIG_NAMES))

# Mark all project names as phony targets
.PHONY: $(ALL_ROOT_NAMES) $(ALL_EXAMPLE_NAMES)

all: build examples
	@echo "✓ All WASM plugins built successfully!"
	@echo "Root projects: $(BUILD_DIR)/"
	@echo "Examples: $(BUILD_DIR)/examples/"

build:
	@echo "=== Building root projects ==="
	@mkdir -p $(BUILD_DIR)
	@$(foreach dir,$(ROOT_GO_PROJECTS), \
		echo "Building Go project: $(notdir $(dir:/=))"; \
		mkdir -p $(BUILD_DIR)/$(notdir $(dir:/=)); \
		cd $(dir) && GOOS=wasip1 GOARCH=wasm go build -o ../$(BUILD_DIR)/$(notdir $(dir:/=))/main.wasm . || exit 1; \
	)
	@$(foreach dir,$(ROOT_RUST_PROJECTS), \
		echo "Building Rust project: $(notdir $(dir:/=))"; \
		mkdir -p $(BUILD_DIR)/$(notdir $(dir:/=)); \
		cd $(dir) && cargo build --release --target wasm32-wasip2 && \
		cp target/wasm32-wasip2/release/$(notdir $(dir:/=)).wasm ../$(BUILD_DIR)/$(notdir $(dir:/=))/main.wasm 2>/dev/null || \
		cp target/wasm32-wasip2/release/$$(echo $(notdir $(dir:/=)) | tr '_' '-').wasm ../$(BUILD_DIR)/$(notdir $(dir:/=))/main.wasm || exit 1; \
	)
	@$(foreach dir,$(ROOT_C_PROJECTS), \
		echo "Building C project: $(notdir $(dir:/=))"; \
		mkdir -p $(BUILD_DIR)/$(notdir $(dir:/=)); \
		clang --target=wasm32-wasi --sysroot=/opt/wasi-sdk/share/wasi-sysroot \
			-o $(BUILD_DIR)/$(notdir $(dir:/=))/main.wasm $(dir)main.c 2>/dev/null || \
		clang --target=wasm32-wasi \
			-o $(BUILD_DIR)/$(notdir $(dir:/=))/main.wasm $(dir)main.c 2>/dev/null || \
		zig cc -target wasm32-wasi -Os \
			-o $(BUILD_DIR)/$(notdir $(dir:/=))/main.wasm $(dir)main.c || \
		(echo "Error: Cannot build C project. Please install wasi-sdk, clang with wasi support, or zig."; exit 1); \
	)
	@$(foreach dir,$(ROOT_ZIG_PROJECTS), \
		echo "Building Zig project: $(notdir $(dir:/=))"; \
		mkdir -p $(BUILD_DIR)/$(notdir $(dir:/=)); \
		zig build-exe $(dir)main.zig -target wasm32-wasi -O ReleaseSmall \
			-femit-bin=$(BUILD_DIR)/$(notdir $(dir:/=))/main.wasm || exit 1; \
	)
	@echo "✓ Built all root projects successfully!"

examples:
	@echo "=== Building example projects ==="
	@mkdir -p $(BUILD_DIR)/examples
	@$(foreach dir,$(EXAMPLE_GO_PROJECTS), \
		echo "Building Go example: $(notdir $(dir:/=))"; \
		mkdir -p $(BUILD_DIR)/examples/$(notdir $(dir:/=)); \
		cd $(dir) && GOOS=wasip1 GOARCH=wasm go build -o ../../$(BUILD_DIR)/examples/$(notdir $(dir:/=))/main.wasm . || exit 1; \
	)
	@$(foreach dir,$(EXAMPLE_RUST_PROJECTS), \
		echo "Building Rust example: $(notdir $(dir:/=))"; \
		mkdir -p $(BUILD_DIR)/examples/$(notdir $(dir:/=)); \
		cd $(dir) && cargo build --release --target wasm32-wasip2 && \
		cp target/wasm32-wasip2/release/$(notdir $(dir:/=)).wasm ../../$(BUILD_DIR)/examples/$(notdir $(dir:/=))/main.wasm 2>/dev/null || \
		cp target/wasm32-wasip2/release/$$(echo $(notdir $(dir:/=)) | tr '_' '-').wasm ../../$(BUILD_DIR)/examples/$(notdir $(dir:/=))/main.wasm || exit 1; \
	)
	@$(foreach dir,$(EXAMPLE_C_PROJECTS), \
		echo "Building C example: $(notdir $(dir:/=))"; \
		mkdir -p $(BUILD_DIR)/examples/$(notdir $(dir:/=)); \
		clang --target=wasm32-wasi --sysroot=/opt/wasi-sdk/share/wasi-sysroot \
			-o $(BUILD_DIR)/examples/$(notdir $(dir:/=))/main.wasm $(dir)main.c 2>/dev/null || \
		clang --target=wasm32-wasi \
			-o $(BUILD_DIR)/examples/$(notdir $(dir:/=))/main.wasm $(dir)main.c 2>/dev/null || \
		zig cc -target wasm32-wasi -Os \
			-o $(BUILD_DIR)/examples/$(notdir $(dir:/=))/main.wasm $(dir)main.c || \
		(echo "Error: Cannot build C project. Please install wasi-sdk, clang with wasi support, or zig."; exit 1); \
	)
	@$(foreach dir,$(EXAMPLE_ZIG_PROJECTS), \
		echo "Building Zig example: $(notdir $(dir:/=))"; \
		mkdir -p $(BUILD_DIR)/examples/$(notdir $(dir:/=)); \
		zig build-exe $(dir)main.zig -target wasm32-wasi -O ReleaseSmall \
			-femit-bin=$(BUILD_DIR)/examples/$(notdir $(dir:/=))/main.wasm || exit 1; \
	)
	@echo "✓ Built all example projects successfully!"

help:
	@echo "Available targets:"
	@echo "  make all            - Build all WASM plugins (root + examples)"
	@echo "  make build          - Build only root level projects"
	@echo "  make examples       - Build all example projects"
	@echo "  make <project>      - Build a specific root project (e.g., make hello_world_go)"
	@echo "  make examples/<xxx> - Build a specific example (e.g., make examples/hello_world_go)"
	@echo "  make clean          - Remove build directory"
	@echo "  make help           - Show this help message"
	@echo ""
	@echo "Available root projects:"
	@$(foreach name,$(ROOT_GO_NAMES),echo "  $(name) (Go)";)
	@$(foreach name,$(ROOT_RUST_NAMES),echo "  $(name) (Rust)";)
	@$(foreach name,$(ROOT_C_NAMES),echo "  $(name) (C)";)
	@$(foreach name,$(ROOT_ZIG_NAMES),echo "  $(name) (Zig)";)
	@echo ""
	@echo "Available example projects:"
	@$(foreach name,$(EXAMPLE_GO_NAMES),echo "  examples/$(name) (Go)";)
	@$(foreach name,$(EXAMPLE_RUST_NAMES),echo "  examples/$(name) (Rust)";)
	@$(foreach name,$(EXAMPLE_C_NAMES),echo "  examples/$(name) (C)";)
	@$(foreach name,$(EXAMPLE_ZIG_NAMES),echo "  examples/$(name) (Zig)";)

clean:
	@echo "Cleaning build directory..."
	@rm -rf $(BUILD_DIR)
	@echo "✓ Clean complete!"

# Individual root project build rules
define build-go-project
	@echo "=== Building Go project: $(1) ==="
	@mkdir -p $(BUILD_DIR)/$(1)
	@cd $(1) && GOOS=wasip1 GOARCH=wasm go build -o ../$(BUILD_DIR)/$(1)/main.wasm .
	@echo "✓ Built $(1) successfully!"
endef

define build-rust-project
	@echo "=== Building Rust project: $(1) ==="
	@mkdir -p $(BUILD_DIR)/$(1)
	@cd $(1) && cargo build --release --target wasm32-wasip2
	@cd $(1) && (cp target/wasm32-wasip2/release/$(1).wasm ../$(BUILD_DIR)/$(1)/main.wasm 2>/dev/null || \
		cp target/wasm32-wasip2/release/$$(echo $(1) | tr '_' '-').wasm ../$(BUILD_DIR)/$(1)/main.wasm)
	@echo "✓ Built $(1) successfully!"
endef

define build-c-project
	@echo "=== Building C project: $(1) ==="
	@mkdir -p $(BUILD_DIR)/$(1)
	@clang --target=wasm32-wasi --sysroot=/opt/wasi-sdk/share/wasi-sysroot \
		-o $(BUILD_DIR)/$(1)/main.wasm $(1)/main.c 2>/dev/null || \
	clang --target=wasm32-wasi \
		-o $(BUILD_DIR)/$(1)/main.wasm $(1)/main.c 2>/dev/null || \
	zig cc -target wasm32-wasi -Os \
		-o $(BUILD_DIR)/$(1)/main.wasm $(1)/main.c || \
	(echo "Error: Cannot build C project. Please install wasi-sdk, clang with wasi support, or zig."; exit 1)
	@echo "✓ Built $(1) successfully!"
endef

define build-zig-project
	@echo "=== Building Zig project: $(1) ==="
	@mkdir -p $(BUILD_DIR)/$(1)
	@zig build-exe $(1)/main.zig -target wasm32-wasi -O ReleaseSmall \
		-femit-bin=$(BUILD_DIR)/$(1)/main.wasm
	@echo "✓ Built $(1) successfully!"
endef

$(ROOT_GO_NAMES):
	$(call build-go-project,$@)

$(ROOT_RUST_NAMES):
	$(call build-rust-project,$@)

$(ROOT_C_NAMES):
	$(call build-c-project,$@)

$(ROOT_ZIG_NAMES):
	$(call build-zig-project,$@)

# Individual example project build rules (examples/xxx)
# Go examples
define make-go-example-rule
$(EXAMPLES_DIR)/$(1):
	@echo "=== Building Go example: $(1) ==="
	@mkdir -p $(BUILD_DIR)/examples/$(1)
	@cd $(EXAMPLES_DIR)/$(1) && GOOS=wasip1 GOARCH=wasm go build -o ../../$(BUILD_DIR)/examples/$(1)/main.wasm .
	@echo "✓ Built examples/$(1) successfully!"
endef

$(foreach name,$(EXAMPLE_GO_NAMES),$(eval $(call make-go-example-rule,$(name))))

# Rust examples
define make-rust-example-rule
$(EXAMPLES_DIR)/$(1):
	@echo "=== Building Rust example: $(1) ==="
	@mkdir -p $(BUILD_DIR)/examples/$(1)
	@cd $(EXAMPLES_DIR)/$(1) && cargo build --release --target wasm32-wasip2
	@cd $(EXAMPLES_DIR)/$(1) && (cp target/wasm32-wasip2/release/$(1).wasm ../../$(BUILD_DIR)/examples/$(1)/main.wasm 2>/dev/null || \
		cp target/wasm32-wasip2/release/$$$$(echo $(1) | tr '_' '-').wasm ../../$(BUILD_DIR)/examples/$(1)/main.wasm)
	@echo "✓ Built examples/$(1) successfully!"
endef

$(foreach name,$(EXAMPLE_RUST_NAMES),$(eval $(call make-rust-example-rule,$(name))))

# C examples
define make-c-example-rule
$(EXAMPLES_DIR)/$(1):
	@echo "=== Building C example: $(1) ==="
	@mkdir -p $(BUILD_DIR)/examples/$(1)
	@clang --target=wasm32-wasi --sysroot=/opt/wasi-sdk/share/wasi-sysroot \
		-o $(BUILD_DIR)/examples/$(1)/main.wasm $(EXAMPLES_DIR)/$(1)/main.c 2>/dev/null || \
	clang --target=wasm32-wasi \
		-o $(BUILD_DIR)/examples/$(1)/main.wasm $(EXAMPLES_DIR)/$(1)/main.c 2>/dev/null || \
	zig cc -target wasm32-wasi -Os \
		-o $(BUILD_DIR)/examples/$(1)/main.wasm $(EXAMPLES_DIR)/$(1)/main.c || \
	(echo "Error: Cannot build C project. Please install wasi-sdk, clang with wasi support, or zig."; exit 1)
	@echo "✓ Built examples/$(1) successfully!"
endef

$(foreach name,$(EXAMPLE_C_NAMES),$(eval $(call make-c-example-rule,$(name))))

# Zig examples
define make-zig-example-rule
$(EXAMPLES_DIR)/$(1):
	@echo "=== Building Zig example: $(1) ==="
	@mkdir -p $(BUILD_DIR)/examples/$(1)
	@zig build-exe $(EXAMPLES_DIR)/$(1)/main.zig -target wasm32-wasi -O ReleaseSmall \
		-femit-bin=$(BUILD_DIR)/examples/$(1)/main.wasm
	@echo "✓ Built examples/$(1) successfully!"
endef

$(foreach name,$(EXAMPLE_ZIG_NAMES),$(eval $(call make-zig-example-rule,$(name))))
