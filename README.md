# WASM Plugins for Linn

This repository contains WebAssembly (WASM) plugins compiled for WASI (WebAssembly System Interface), demonstrating how to build plugins in multiple languages that can run in a WASM runtime.

English | [简体中文](README_CN.md)

## Features

- 🚀 Multi-language support (Go, Rust, C, and Zig)
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

### For C Projects
- One of the following:
  - [WASI SDK](https://github.com/WebAssembly/wasi-sdk)
  - Clang with WASI support
  - Zig compiler (can be used as a C compiler)

### For Zig Projects
- Zig compiler

## Quick Start

### Building Plugins

```bash
# Build all plugins (Go + Rust + C + Zig)
make all
```

## Output

All compiled WASM files are placed in the `build/` directory:

## WASI Versions

- **Go plugins**: Use WASI Preview 1 (wasip1)
- **Rust plugins**: Use WASI Preview 2 (wasip2)
- **C plugins**: Use WASI (wasm32-wasi target)
- **Zig plugins**: Use WASI (wasm32-wasi target)

WASI Preview 2 offers improved performance and additional features compared to Preview 1, but both are supported by modern WASM runtimes.

## Running Plugins

To run the compiled WASM plugins, you'll need a WASI-compatible runtime such as:

- [Wasmtime](https://wasmtime.dev/)
- [Wasmer](https://wasmer.io/)
- [WasmEdge](https://wasmedge.org/)
