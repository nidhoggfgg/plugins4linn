# Linn WASM 插件集

本仓库包含为 WASI（WebAssembly 系统接口）编译的 WebAssembly (WASM) 插件，展示了如何使用多种编程语言构建可在 WASM 运行时中运行的插件。

[English](README.md) | 简体中文

## 特性

- 🚀 多语言支持（Go 和 Rust）
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

## 快速开始

### 构建插件

```bash
# 构建所有插件（Go + Rust）
make all

# 仅构建 Go 插件
make build-go

# 仅构建 Rust 插件
make build-rust

# 显示所有可用命令
make help

# 清理构建产物
make clean
```

## 输出

所有编译后的 WASM 文件都会放置在 `build/` 目录中：

```
build/
  ├── hello_world_go/
  │   └── main.wasm
  └── hello_world_rs/
      └── main.wasm
```

## 项目结构

```
plugins4linn/
├── Makefile                  # 构建自动化
├── hello_world_go/           # Go WASM 插件（WASI Preview 1）
│   ├── go.mod
│   └── main.go
├── hello_world_rs/           # Rust WASM 插件（WASI Preview 2）
│   ├── Cargo.toml
│   └── src/
│       └── main.rs
└── build/                    # 输出目录（自动生成）
    ├── hello_world_go/
    │   └── main.wasm
    └── hello_world_rs/
        └── main.wasm
```

## 现有插件

### hello_world_go
一个简单的基于 Go 的 WASM 插件，演示使用 Preview 1 的基本 WASI 功能。

**技术栈**：Go，使用 `GOOS=wasip1` 和 `GOARCH=wasm`

### hello_world_rs  
一个简单的基于 Rust 的 WASM 插件，演示使用 Preview 2 的基本 WASI 功能。

**技术栈**：Rust，使用 `wasm32-wasip2` 目标

## 添加新插件

构建系统会根据目录结构自动检测新插件。

### 添加 Go 插件

1. 在项目根目录创建新目录：
   ```bash
   mkdir my_new_plugin_go
   ```

2. 创建 `main.go` 文件：
   ```go
   package main
   
   func main() {
       println("Hello from my new plugin!")
   }
   ```

3. 添加 `go.mod` 文件：
   ```bash
   cd my_new_plugin_go
   go mod init my_new_plugin_go
   ```

4. 构建：
   ```bash
   make build-go
   ```

### 添加 Rust 插件

1. 创建新目录并初始化 Cargo 项目：
   ```bash
   mkdir my_new_plugin_rs
   cd my_new_plugin_rs
   cargo init
   ```

2. 在 `src/main.rs` 中编写插件代码：
   ```rust
   fn main() {
       println!("Hello from my new plugin!");
   }
   ```

3. 构建：
   ```bash
   make build-rust
   ```

## WASI 版本

- **Go 插件**：使用 WASI Preview 1 (wasip1)
- **Rust 插件**：使用 WASI Preview 2 (wasip2)

与 Preview 1 相比，WASI Preview 2 提供了改进的性能和额外的功能，但两者都受到现代 WASM 运行时的支持。

## 运行插件

要运行编译后的 WASM 插件，您需要一个兼容 WASI 的运行时，例如：

- [Wasmtime](https://wasmtime.dev/)
- [Wasmer](https://wasmer.io/)
- [WasmEdge](https://wasmedge.org/)

使用 Wasmtime 的示例：
```bash
# 安装 wasmtime
curl https://wasmtime.dev/install.sh -sSf | bash

# 运行插件
wasmtime build/hello_world_go/main.wasm
wasmtime build/hello_world_rs/main.wasm
```

## 贡献

欢迎添加更多插件或改进现有插件。只要遵循项目结构约定，自动化构建系统就会处理编译工作。

## 许可证

本项目按原样提供，仅用于演示目的。

