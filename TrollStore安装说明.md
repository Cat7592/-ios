# TrollStore 安装说明

## 什么是 TrollStore？

TrollStore 是一款利用 iOS CoreTrust 漏洞实现永久签名的工具，允许在不越狱的情况下安装任意 IPA 应用。支持 iOS 14.0 - 16.6.1 / 17.0。

> ⚠️ **免责声明**: 使用 TrollStore 安装第三方应用可能违反 Apple 的服务条款。请仅用于合法的个人用途。

---

## 前置条件

### 支持的设备与系统

| iOS 版本 | 支持状态 | 说明 |
|----------|----------|------|
| 14.0 - 14.8.1 | ✅ 完全支持 | 所有设备 |
| 15.0 - 15.4.1 | ✅ 完全支持 | 所有设备 |
| 15.5 - 15.6.1 | ✅ 支持 | 需要安装方式略有不同 |
| 16.0 - 16.6.1 | ✅ 完全支持 | 所有设备 |
| 17.0 | ✅ 完全支持 | A11 及以下设备 |
| 17.0.1+ | ❌ 不支持 | CoreTrust 漏洞已修复 |

### 硬件要求
- iPhone / iPad 支持上述 iOS 版本
- 至少 200MB 可用存储空间
- 稳定的网络连接（用于首次下载应用）

---

## 安装步骤

### 第一步: 安装 TrollStore

如果设备尚未安装 TrollStore，请按以下步骤操作：

#### 方法 A: 在线安装（推荐）

1. 在 iOS Safari 浏览器中打开: [https://ios.cfw.guide/installing-trollstore/](https://ios.cfw.guide/installing-trollstore/)
2. 根据你的 iOS 版本选择对应的安装指南
3. 常用的安装器:
   - **TrollInstallerX**: 适用于 iOS 14.0 - 16.6.1
   - **TrollHelperOTA**: 适用于 iOS 15.0 - 15.4.1
   - **TrollRestore**: 适用于特定版本

#### 方法 B: 通过 AltStore / Sideloadly

1. 在电脑上下载 [AltStore](https://altstore.io/) 或 [Sideloadly](https://sideloadly.io/)
2. 下载 TrollStore 安装器的 IPA
3. 使用 AltStore/Sideloadly 签名并安装到设备
4. 在设备上打开安装器，按照提示安装 TrollStore

### 第二步: 获取猫老大解析助手 IPA

#### 🥇 方法 A: GitHub Actions 自动打包（⭐ 推荐，无需 Mac）

**最简单的方式，push 代码即可自动构建 IPA，无需安装任何开发环境。**

1. Fork 本仓库到你的 GitHub 账号
2. 在仓库 **Settings → Secrets and variables → Actions** 添加 `EXPO_TOKEN`
   - Token 在 [Expo 官网](https://expo.dev/settings/access-tokens) 创建
3. 进入 **Actions** 标签页 → 选择 **Build iOS IPA** → **Run workflow**
4. 等待构建完成（约 15-30 分钟）
5. 在 Actions 运行页面底部的 **Artifacts** 区域下载 IPA

> 推送代码到 main 分支也会自动触发构建。

#### 🥈 方法 B: 本地命令行（需要 Node.js）

```bash
cd maolaoda-parser
npm install
eas build --platform ios --profile production
```

等待云端构建完成，在 Expo 控制台下载 IPA。

#### 🥉 方法 C: 本地构建（需要 macOS + Xcode）

```bash
cd maolaoda-parser
npm install
eas build --platform ios --profile production --local
```

生成的 IPA 文件位于项目根目录。

### 第三步: 传输 IPA 到设备

#### 方法 1: AirDrop（推荐）
1. 在 Mac 上右键点击 IPA 文件
2. 选择 "共享" → "AirDrop"
3. 选择你的 iOS 设备
4. 在 iOS 设备上接受传输

#### 方法 2: 文件 App + iCloud
1. 将 IPA 上传到 iCloud Drive
2. 在 iOS 设备上打开"文件"App
3. 找到 IPA 文件并下载

#### 方法 3: 本地网络传输
使用以下任一工具:
- [LocalSend](https://localsend.org/) (免费开源)
- [Snapdrop](https://snapdrop.net/) (网页版)
- iTunes 文件共享

### 第四步: 在 TrollStore 中安装

1. 在 iOS 设备上打开 **TrollStore** 应用
2. 点击右上角的 **+** 按钮
3. 选择 "Import from Files"（从文件导入）
4. 找到并选择 `maolaoda-parser-*.ipa` 文件
5. 等待安装完成（通常 5-15 秒）
6. 应用图标将出现在主屏幕

### 第五步: 首次使用设置

1. 点击主屏幕上的 **猫老大解析助手** 图标
2. 首次打开会请求以下权限:
   - 📸 **相册访问权限**: 用于保存下载的图片和视频 → 选择"允许"
   - 📋 **剪贴板访问**: 用于自动检测分享链接 → 选择"允许"
3. 完成授权后即可正常使用

---

## 卸载

### 卸载应用
1. 长按主屏幕上的应用图标
2. 选择"删除 App"
3. 确认删除

### 卸载 TrollStore
1. 打开 TrollStore 应用
2. 进入 Settings
3. 点击 "Uninstall TrollStore"
4. 设备将自动重启完成卸载

---

## 常见问题

### Q: IPA 安装后闪退？
**A:** 可能的原因和解决方法:
1. TrollStore 版本过旧 → 更新到最新版
2. iOS 版本不兼容 → 确认版本在支持列表中
3. 尝试在 TrollStore 中点击应用 → "Switch to User Registration"

### Q: 安装后没有图标？
**A:** 
1. 重启设备（强制重启）
2. 在 TrollStore 中点击 "Rebuild Icon Cache"

### Q: 下载的文件在哪里？
**A:** 
- 应用内部的下载目录中
- 如果开启了"自动保存到相册"，图片/视频也会保存到系统相册
- 可在应用的"下载管理"页面查看和管理文件

### Q: 应用更新怎么办？
**A:**
1. 在 GitHub 仓库 push 新代码自动触发构建
2. 或手动在 Actions 页面触发 Build iOS IPA
3. 下载新版本 IPA，TrollStore 导入即可覆盖旧版本（保留数据）

### Q: 没有 Mac 怎么构建 IPA？
**A:** 使用 **GitHub Actions 自动打包**——完全免费，无需 Mac。仓库已内置 workflow，只需在 Settings 中配置 `EXPO_TOKEN` secret 即可一键构建。

### Q: GitHub Artifact 下载链接过期了？
**A:** Artifact 保留 90 天。过期后重新触发 Actions 构建生成新的 IPA 即可。

### Q: 是否可以安装到多个设备？
**A:** 可以。TrollStore 的签名是设备绑定的，每台设备需要独立安装。

---

## 安全提醒

1. **仅从可信来源获取 IPA 文件**
2. **不要在应用内输入敏感个人信息**
3. **下载的内容请遵守相关版权法规**
4. **定期清理下载文件以释放存储空间**
5. **TrollStore 本身是开源项目，可从 [GitHub](https://github.com/opa334/TrollStore) 获取**

---

## 技术支持

如有问题，可以通过以下方式获取帮助:
- GitHub Issues: 项目仓库提交问题
- TrollStore 社区: [r/TrollStore](https://reddit.com/r/TrollStore) (Reddit)
- TrollStore Discord: 官方 Discord 服务器

---

**猫老大解析助手** v1.0.0 | 仅供学习研究使用
