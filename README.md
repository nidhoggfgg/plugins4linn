# WASM Plugins for Linn

This repository contains WebAssembly (WASM) plugins compiled for WASI (WebAssembly System Interface), demonstrating how to build plugins in multiple languages that can run in a WASM runtime.

English | [简体中文](README_CN.md)

## Features

- 🚀 Multi-language support (Go and Rust)
- 🔧 Automated build system using Make
- 📦 WASI-compliant plugins (Preview 1 for Go, Preview 2 for Rust)
- 🎯 Simple and extensible structure for adding new plugins

## Prerequisites

### For Go Projects
- Go 1.21 or later
- WASI support (GOOS=wasip1)

### For Rust Projects
- Rust toolchain (stable recommended)
- wasm32-wasip2 target:
  ```bash
  rustup target add wasm32-wasip2
  ```

## Quick Start

### Building Plugins

```bash
# Build all plugins (Go + Rust)
make all

# Build only Go plugins
make build-go

# Build only Rust plugins
make build-rust

# Show all available commands
make help

# Clean build artifacts
make clean
```

## Output

All compiled WASM files are placed in the `build/` directory:

```
build/
  ├── hello_world_go/
  │   └── main.wasm
  └── hello_world_rs/
      └── main.wasm
```

## Project Structure

```
plugins4linn/
├── Makefile                  # Build automation
├── hello_world_go/           # Go WASM plugin (WASI Preview 1)
│   ├── go.mod
│   └── main.go
├── hello_world_rs/           # Rust WASM plugin (WASI Preview 2)
│   ├── Cargo.toml
│   └── src/
│       └── main.rs
└── build/                    # Output directory (generated)
    ├── hello_world_go/
    │   └── main.wasm
    └── hello_world_rs/
        └── main.wasm
```

## Current Plugins

### hello_world_go
A simple Go-based WASM plugin that demonstrates basic WASI functionality using Preview 1.

**Technology**: Go with `GOOS=wasip1` and `GOARCH=wasm`

### hello_world_rs  
A simple Rust-based WASM plugin that demonstrates basic WASI functionality using Preview 2.

**Technology**: Rust with `wasm32-wasip2` target

## Adding New Plugins

The build system automatically detects new plugins based on directory structure.

### Adding a Go Plugin

1. Create a new directory in the project root:
   ```bash
   mkdir my_new_plugin_go
   ```

2. Create a `main.go` file:
   ```go
   package main
   
   func main() {
       println("Hello from my new plugin!")
   }
   ```

3. Add a `go.mod` file:
   ```bash
   cd my_new_plugin_go
   go mod init my_new_plugin_go
   ```

4. Build:
   ```bash
   make build-go
   ```

### Adding a Rust Plugin

1. Create a new directory and initialize a Cargo project:
   ```bash
   mkdir my_new_plugin_rs
   cd my_new_plugin_rs
   cargo init
   ```

2. Write your plugin in `src/main.rs`:
   ```rust
   fn main() {
       println!("Hello from my new plugin!");
   }
   ```

3. Build:
   ```bash
   make build-rust
   ```

## WASI Versions

- **Go plugins**: Use WASI Preview 1 (wasip1)
- **Rust plugins**: Use WASI Preview 2 (wasip2)

WASI Preview 2 offers improved performance and additional features compared to Preview 1, but both are supported by modern WASM runtimes.

## Running Plugins

To run the compiled WASM plugins, you'll need a WASI-compatible runtime such as:

- [Wasmtime](https://wasmtime.dev/)
- [Wasmer](https://wasmer.io/)
- [WasmEdge](https://wasmedge.org/)

Example with Wasmtime:
```bash
# Install wasmtime
curl https://wasmtime.dev/install.sh -sSf | bash

# Run a plugin
wasmtime build/hello_world_go/main.wasm
wasmtime build/hello_world_rs/main.wasm
```

## Contributing

Feel free to add more plugins or improve existing ones. The automated build system will handle compilation as long as you follow the project structure conventions.

## License

This project is provided as-is for demonstration purposes.
