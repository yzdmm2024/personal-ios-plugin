# 胖虎连点器 — 巨魔(TrollStore) 自包含 IPA（完整版）

本分支对应**桌面完整版**「胖虎连点器」UI（左侧 点击/双击/长按/滑动/等待/识图/识字/跳转/条件，底部运行状态）。
已改为**巨魔专用**：用 `IOHIDUserDevice` 虚拟触摸设备注入触摸，编译产物是独立 dylib（不依赖 CydiaSubstrate）。

为彻底绕开「不会手动签 entitlements」「TrollFools 注入失败」这两类最常见卡点，
本工程现在提供一个**自包含 IPA**：宿主 App + 内嵌 dylib + 已签好的 `get-properties` 授权，打包成一个文件。
你用 TrollStore 直接装这**一个 .ipa** 即可，无需任何手动签名/注入。

## 编译（GitHub Actions 自动完成）

推送 `main` / `ci/build` / `ci/build-fatihu` 分支会自动在 macOS runner 上：
1. 编译 `AutoClicker.dylib`（arm64，无 CydiaSubstrate 依赖）
2. 编译最小宿主 App `ACHost`
3. 组装 `.app` → 嵌入 dylib → 用 `entitlements` 签名 → 打包 `AutoClicker.ipa`

- 手动触发：仓库 **Actions → Build AutoClicker → Run workflow**
- 产物下载：该次运行的 **Artifacts → AutoClicker-ipa**（含 `AutoClicker.ipa` + `Entitlements.plist`）
- 另提供 **AutoClicker-dylib** 构件，给想手动注入到别的宿主 App 的人用

## 在巨魔设备上使用（推荐：自包含 IPA）

1. 从 Actions 运行下载 **`AutoClicker.ipa`**。
2. 用 **TrollStore** 打开/分享安装这个 `.ipa`。
   - 安装时若提示选择 entitlements，选同包的 **`Entitlements.plist`**（IPA 内已签好，通常自动沿用）。
3. 桌面出现「AutoClicker」图标 → 打开 → 出现悬浮控制面板 → 音量键启动脚本。
4. 见下方「验证」看 `[触]` 诊断。

## 备选：手动注入到别的宿主 App（dylib 构件）

> ⚠️ **最关键：宿主 App 必须带 `get-properties` 授权，否则虚拟触摸设备创建失败、点击必然无效。**
> TrollFools 注入**不会自动加授权**，很多人"点了没反应"就是卡在这。

1. 用 TrollFools 把 `AutoClicker.dylib` 注入你的宿主 App，且**宿主 App 必须已用 `Entitlements.plist` 重签**
   （TrollStore 重装时选 custom entitlements，或 `ldid -S Entitlements.plist HostApp`）。
2. 打开宿主 App → 出现悬浮面板 → 音量键启动。

## 验证（直接看浮窗，无需系统日志）

新版 dylib 把触摸诊断**直接显示在浮窗日志区**（前缀 `[触]`），打开 App 看一眼即可：

- `[触] 虚拟触摸设备创建成功 (get-properties OK)` → 授权 OK，链路通了，点击应生效。
- `[触] 已获取虚拟设备真实 senderID: 0x...` → 已自动用系统分配的真实 senderID 派发（不再用固定值）。
- `[触] 虚拟触摸设备创建失败！...` → 宿主 App 没拿到授权（IPA 方式一般不会；手动注入才会）。
- `[触] 触摸派发失败: 虚拟设备=N ...` → IOHID 私有符号缺失（罕见，iOS 版本差异）。

> 浮窗看不到 `[触]` 时，电脑 `idevicesyslog | grep [触]`，或 Mac Xcode → 设备与模拟器 → 控制台过滤 `[AC]`。

## 已知限制（诚实告知）

- **识别/识图（OCR、模板匹配）只能截到宿主 App 自身画面**。`drawViewHierarchyInRect`
  无法截到别的 App，这是 iOS 平台硬限制，非代码问题。跨 App 识图请改用「手动截图表模板」方案。
- senderID 已改为**自动获取虚拟设备真实 ID**（不再用固定值），兼容 iOS 15/16 巨魔环境。
