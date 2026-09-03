# AutoClicker — 巨魔(TrollStore) dylib 编译与使用

本仓库已改为**巨魔专用 dylib 插件**：用 `IOHIDUserDevice` 虚拟触摸设备注入触摸，
编译产物是独立 dylib（不依赖 CydiaSubstrate），可直接经 TrollFools / TrollStore 注入宿主 App。

## 编译（GitHub Actions 自动完成）

仓库接入了 GitHub Actions：推送 `main` 或 `ci/build` 分支会自动在 macOS runner 上
用 Xcode 自带 iOS SDK 编译 `AutoClicker.dylib` 并作为构件(artifact)上传。

- 手动触发：仓库 **Actions → Build AutoClicker dylib → Run workflow**
- 产物下载：该次运行的 **Artifacts → AutoClicker-dylib**

本地（需 macOS + Xcode）也可编译，命令同 `build.yml` 里的 Compile 步骤。

## 在巨魔设备上使用

1. 准备一个宿主 App（任意 IPA，例如一个空白壳 App）。
2. **给宿主 App 签上 `entitlements.xml`**（触摸注入关键授权）：
   - 用 TrollStore 安装时选 custom entitlements，或
   - `ldid -S entitlements.xml HostApp` 重签后再装入 TrollStore。
   - 缺少 `com.apple.private.iokit.get-properties` → 虚拟触摸设备创建失败、点击无效。
3. 用 TrollFools（或 TrollStore 的注入功能）把 `AutoClicker.dylib` 注入宿主 App。
4. 打开宿主 App → 出现悬浮控制面板 → 音量键启动脚本。

## 验证（看日志）

- 设备日志搜 `[AC]`：
  - `虚拟触摸设备创建成功 (get-properties OK)` → 触摸链路正常。
  - `虚拟触摸设备创建失败！确认宿主 App 已带 ...get-properties 授权` → 宿主 App 授权没签上。
  - `触摸派发失败: 虚拟设备=N 客户端=N` → IOHID 符号缺失（罕见，iOS 版本差异）。
- 也可用 frida 挂在宿主 App 上抓日志。

## 已知限制（诚实告知）

- **识别/识图（OCR、模板匹配）只能截到宿主 App 自身画面**。`drawViewHierarchyInRect`
  无法截到别的 App，这是 iOS 平台硬限制，非代码问题。跨 App 识图请改用「手动截图表模板」方案。
- `senderID` 用的是固定值 `0x10000027F`。若设备创建成功但点击仍不生效，
  需用 frida 抓虚拟设备真实 senderID 替换 `kIOHIDEventDigitizerSenderID`。
