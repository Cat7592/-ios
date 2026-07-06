# 🐱 猫老大解析助手

> 多平台社交媒体内容解析与下载工具 · 支持抖音/快手/TikTok/小红书

<p align="center">
  <img src="https://img.shields.io/badge/iOS-16.0%2B-blue?logo=apple" alt="iOS">
  <img src="https://img.shields.io/badge/TrollStore-✅-orange" alt="TrollStore">
  <img src="https://img.shields.io/badge/Swift-5.0-FA7343?logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/SwiftUI-native-purple" alt="SwiftUI">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
  <img src="https://img.shields.io/github/actions/workflow/status/maolaoda/maolaoda-parser/build.yml?label=Build%20IPA&logo=github" alt="Build IPA">
</p>

---

## 📱 功能特性

- 🔍 智能识别抖音/快手/TikTok/小红书分享链接
- 📝 深度解析文案、作者、统计数据、标签
- 📥 图片批量下载 + 视频多分辨率下载
- 📊 实时下载进度，自动保存到相册
- 🔒 纯本地存储，零数据上传

---

## 🚀 打包 IPA（GitHub Actions · ⭐ 推荐）

**无需 Mac！Push 代码即自动构建无签名 IPA → TrollStore 安装。**

### 首次配置（仅一次）

在 GitHub 仓库 **Settings → Actions → General → Workflow permissions** 勾选 **Read and write permissions**。

### 使用方式

| 触发 | 说明 |
|------|------|
| **自动** | push 到 `main`/`master` 分支 |
| **手动** | Actions → **Build Unsigned IPA** → Run workflow |

构建完成后在 Actions 页面底部 **Artifacts** 下载 `.ipa`，保留 90 天。

### Workflow 流程

```
push / 手动触发
    │
    ▼
 macos-14 上:
    ├── gem install xcodeproj
    ├── ruby create_xcodeproj.rb  → 生成 .xcodeproj + xcscheme
    ├── xcodebuild archive        → 无签名编译
    ├── zip Payload/ → .ipa
    └── upload-artifact           → 可下载
```

---

## 📁 项目结构

```
maolaoda-parser/
├── .github/workflows/build.yml         # 无签名 IPA 构建
├── App/                                # 入口 + 配置
│   ├── maolaoda_parserApp.swift        # @main
│   ├── Info.plist
│   └── Entitlements.plist
├── Models/                             # 数据模型
│   ├── PlatformType.swift
│   ├── ParseResult.swift
│   ├── DownloadTask.swift
│   └── AppSettings.swift
├── Services/                           # 业务逻辑
│   ├── URLDetector.swift               # URL 识别
│   ├── PlatformParser.swift            # 协议 + 基类
│   ├── DouyinParser.swift
│   ├── KuaishouParser.swift
│   ├── TikTokParser.swift
│   ├── XiaohongshuParser.swift
│   ├── ParserService.swift             # 调度器
│   └── DownloadService.swift           # URLSession 下载
├── ViewModels/
│   ├── ParserViewModel.swift
│   └── DownloadViewModel.swift
├── Views/                              # SwiftUI 界面
│   ├── ContentView.swift               # Tab 导航
│   ├── HomeView.swift
│   ├── LinkInputView.swift
│   ├── ParserResultView.swift
│   ├── MediaGridView.swift
│   ├── PreviewView.swift
│   ├── DownloadsView.swift
│   └── SettingsView.swift
├── Scripts/
│   ├── create_xcodeproj.rb             # Ruby 生成 .xcodeproj
│   └── create_xcodeproj.sh
└── assets/                             # 图标资源
```

---

## 🏗️ 技术栈

| 层 | 技术 |
|----|------|
| UI | SwiftUI (iOS 16+) |
| 架构 | MVVM (ObservableObject + @Published) |
| 网络 | URLSession (async/await) + URLSessionDownloadDelegate |
| 解析 | NSRegularExpression + JSONSerialization (无三方依赖) |
| 构建 | xcodebuild archive（无签名） + Ruby xcodeproj gem |

---

## ⚙️ 本地开发 (macOS)

```bash
# 1. 安装 xcodeproj gem
gem install xcodeproj

# 2. 生成 Xcode 项目
ruby Scripts/create_xcodeproj.rb

# 3. 打开项目
open maolaoda-parser.xcodeproj

# 4. 在 Xcode 中 ⌘R 运行
```

---

## 📄 许可证

MIT License

---

**🐱 猫老大解析助手** v1.0.0
