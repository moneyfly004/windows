# Windows 构建设置指南

## GitHub Actions 环境设置

### 1. 基本环境（已自动配置）
- ✅ `windows-latest` runner（已配置）
- ✅ Flutter 3.24.0（已配置）
- ✅ Visual Studio Build Tools（通常已预装）

### 2. 检查 Flutter 环境
构建步骤会自动运行：
```powershell
flutter doctor -v
```

### 3. 可能需要的额外设置

#### 如果构建失败，检查以下内容：

**A. Flutter Windows 桌面支持**
```powershell
flutter config --enable-windows-desktop
flutter doctor
```

**B. Visual Studio 构建工具**
- GitHub Actions 的 `windows-latest` 通常已包含
- 如果缺失，需要安装：
  - Visual Studio 2022 Build Tools
  - Windows 10/11 SDK
  - CMake

**C. 依赖检查**
- libcore 库文件已自动下载
- 所有 Dart 依赖已自动安装

## 构建流程

1. **准备阶段**：
   - 生成翻译文件
   - 下载 libcore 库文件
   - 运行代码生成

2. **构建阶段**：
   - `flutter build windows --target lib/main_prod.dart --release`
   - 输出到 `build\windows\x64\runner\Release`

3. **打包阶段**（可选）：
   - 使用 `flutter_distributor` 打包为 exe/msix
   - 或直接使用 build 目录

## 常见问题排查

### 问题 1: Flutter build 失败
**检查**：
- 查看构建日志中的具体错误
- 运行 `flutter doctor -v` 查看缺失的依赖
- 检查是否有编译错误

### 问题 2: 找不到构建输出
**检查**：
- `build\windows\x64\runner\Release` 目录是否存在
- 是否有文件生成

### 问题 3: 依赖下载失败
**检查**：
- 网络连接
- GitHub 访问是否正常
- libcore 下载是否成功

## 当前 Workflow 配置

- ✅ 已添加详细的错误处理
- ✅ 已添加 Flutter doctor 检查
- ✅ 已添加构建输出捕获
- ✅ 已添加详细的日志输出

## 下一步

如果构建仍然失败，请：
1. 查看 GitHub Actions 的完整日志
2. 检查 Flutter doctor 输出
3. 查看构建步骤中的具体错误信息
4. 根据错误信息进行相应修复

