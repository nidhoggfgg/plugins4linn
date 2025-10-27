# Linn WASM 插件集

本仓库包含为 WASI（WebAssembly 系统接口）编译的 WebAssembly (WASM) 插件，展示了如何使用多种编程语言构建可在 WASM 运行时中运行的插件。

[English](README.md) | 简体中文

## 特性

- 🚀 多语言支持（Go、Rust、C 和 Zig）
- 🔧 使用 Make 的自动化构建系统
- 📦 符合 WASI 标准的插件（Go 使用 Preview 1，Rust 使用 Preview 2）
- 🎯 简单且可扩展的插件结构

## 环境要求

### Go 项目
- Go 1.21 或更高版本
- WASI 支持 (GOOS=wasip1)

### Rust 项目
- Rust 工具链（推荐使用 stable 版本）
- wasm32-wasip2 编译目标：
  ```bash
  rustup target add wasm32-wasip2
  ```

### C 项目
- 以下任意一种：
  - [WASI SDK](https://github.com/WebAssembly/wasi-sdk)
  - 支持 WASI 的 Clang
  - Zig 编译器（可用作 C 编译器）

### Zig 项目
- Zig 编译器

## 快速开始

### 构建插件

```bash
# 构建所有插件（Go + Rust + C + Zig）
make all
```

## 输出

所有编译后的 WASM 文件都会放置在 `build/` 目录中：

## WASI 版本

- **Go 插件**：使用 WASI Preview 1 (wasip1)
- **Rust 插件**：使用 WASI Preview 2 (wasip2)
- **C 插件**：使用 WASI (wasm32-wasi 目标)
- **Zig 插件**：使用 WASI (wasm32-wasi 目标)

## 运行插件

要运行编译后的 WASM 插件，您需要一个兼容 WASI 的运行时，例如：

- [Wasmtime](https://wasmtime.dev/)
- [Wasmer](https://wasmer.io/)
- [WasmEdge](https://wasmedge.org/)
