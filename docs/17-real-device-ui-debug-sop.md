# 真机 UI 排查与截图取证 SOP

## 1. 文档目的

本文档定义 ToyLink AI 在 Android 真机上排查 UI 问题时的标准流程。

它主要解决以下问题：

1. 真机上看到的页面和当前代码不一致。
2. 某个按钮、标题、返回行为在真机上“有时有、有时没有”。
3. 怀疑安装的不是最新构建，而是旧包。
4. 需要给导航、状态、页面渲染问题留下一份可回看的证据。

这份 SOP 的核心原则是：

- 先取证，再判断。
- 先确认真机实际画面，再猜测代码原因。
- 不把“我以为手机上应该是这样”当成事实。

## 2. 适用场景

以下情况默认使用本 SOP：

- 首页、扫描页、控制页、设置页、聊天页显示与预期不一致。
- 用户反馈“按钮不见了”“返回会退出应用”“页面不像最新版本”。
- 改了 Flutter 页面代码，但真机表现没有变化。
- 需要确认某次修复是否真的已经装到手机上。

## 3. 前置条件

执行前需要满足：

- Android 真机已连接电脑。
- `adb` 可用。
- 设备已开启 USB 调试。
- ToyLink AI 已安装到真机。

Windows 默认命令示例：

```powershell
& "C:\Users\admini\AppData\Local\Android\Sdk\platform-tools\adb.exe" devices
```

如果能看到形如 `device` 的在线设备，就说明可以继续。

## 4. 标准排查流程

### 4.1 先确认当前前台是否真的是 ToyLink AI

```powershell
& "C:\Users\admini\AppData\Local\Android\Sdk\platform-tools\adb.exe" shell dumpsys activity top | Select-String "ACTIVITY com.example.toylink_ai"
```

目标：

- 确认真机当前显示的是 `com.example.toylink_ai/.MainActivity`
- 避免抓到别的页面或系统弹窗

### 4.2 抓取当前真机屏幕

不要用 PowerShell 直接把 `exec-out` 重定向到本地文件。那样很容易把 PNG 二进制内容弄坏。

错误示例：

```powershell
adb exec-out screencap -p > local.png
```

推荐使用“两步法”：

1. 先让手机把截图保存到自身存储。
2. 再把原始 PNG 拉回电脑。

```powershell
& "C:\Users\admini\AppData\Local\Android\Sdk\platform-tools\adb.exe" shell screencap -p /sdcard/toylink_screen.png
& "C:\Users\admini\AppData\Local\Android\Sdk\platform-tools\adb.exe" pull /sdcard/toylink_screen.png "C:\Users\admini\Documents\New project 8\docs\evidence\device-current-screen.png"
```

### 4.3 查看截图并记录结论

查看截图时，至少确认以下几点：

- 页面标题是否正确。
- 关键按钮是否存在。
- 当前设备状态文案是否符合预期。
- 返回按钮、顶部栏、浮层、错误提示是否出现。
- 页面内容是否明显仍是旧版本 UI。

建议把结论写成一句清晰的话，例如：

- “当前真机控制页没有左上角返回按钮。”
- “当前真机控制页不是最新版本，因为顶部返回卡片没有出现。”
- “页面标题已更新为中文，说明新包已生效。”

## 5. 构建与安装核对流程

如果截图显示的内容不像最新代码，默认先怀疑“真机跑的不是新构建”。

### 5.1 重新完整构建

```powershell
flutter build apk --debug
```

### 5.2 安装新构建

如果应用正在运行，建议先停掉再安装：

```powershell
& "C:\Users\admini\AppData\Local\Android\Sdk\platform-tools\adb.exe" shell am force-stop com.example.toylink_ai
& "C:\Users\admini\AppData\Local\Android\Sdk\platform-tools\adb.exe" install -r -g "C:\Users\admini\Documents\New project 8\build\app\outputs\flutter-apk\app-debug.apk"
```

### 5.3 核对手机上的安装时间

```powershell
& "C:\Users\admini\AppData\Local\Android\Sdk\platform-tools\adb.exe" shell dumpsys package com.example.toylink_ai | Select-String "lastUpdateTime"
```

判断原则：

- 如果 `lastUpdateTime` 没变，大概率还是旧包。
- 如果 `lastUpdateTime` 已更新，再重新启动应用并复测页面。

### 5.4 启动应用

```powershell
& "C:\Users\admini\AppData\Local\Android\Sdk\platform-tools\adb.exe" shell am start -n com.example.toylink_ai/com.example.toylink_ai.MainActivity
```

## 6. 导航问题的专门检查点

如果问题和“返回键”“页面栈”“进入路径不同”有关，除了抓图，还要额外确认：

- 从哪个入口进入页面
- 是 `push` 还是 `go`
- 控制页是否显式提供了兜底返回入口
- 系统返回键是否触发了 `pop`
- 没有上一级页面时是否会跳回 `/home`

对这类问题，建议按“路径”分别验证：

1. `首页 -> 手动控制`
2. `首页 -> 设备状态 -> 扫描 -> 连接 -> 手动控制`
3. `一键启动 -> 手动控制`

不要只测一条路径就认为导航已经修好。

## 7. 常见误判

### 7.1 代码改了，但 APK 没重新构建

这是最常见问题。

表现：

- 本地代码已经有新按钮
- 真机截图里仍然没有
- 重新安装的其实是旧 APK

### 7.2 装了包，但应用进程还是旧状态

表现：

- 手机没完全重启应用
- 仍停留在旧页面状态

处理：

- `force-stop`
- 重新安装
- 再次启动
- 再抓图确认

### 7.3 只看口头描述，不取证

表现：

- 团队根据“我看到好像没有”来推断代码问题
- 最后发现是路径不同、包不同、缓存不同

处理：

- 必须抓图
- 必须核对前台 Activity
- 必须核对安装时间

## 8. 证据留存规则

所有真机 UI 排查建议在 `docs/evidence/` 下留档。

推荐命名：

- `device-current-screen-YYYY-MM-DD-HHMM.png`
- `ui-debug-note-YYYY-MM-DD.md`

排查记录至少包含：

- 复现路径
- 抓图时间
- 当前前台 Activity
- 当前安装包更新时间
- 观察到的现象
- 最终结论

## 9. 最小记录模板

```markdown
# 真机 UI 排查记录

- 日期：
- 设备：
- 路径：
- 当前前台 Activity：
- 包更新时间：
- 截图文件：
- 现象：
- 结论：
- 后续动作：
```

## 10. 对 ToyLink AI 的默认要求

从本 SOP 生效开始，ToyLink AI 后续凡是出现“真机 UI 和代码不一致”的问题，默认按以下顺序处理：

1. 确认前台 Activity
2. 抓真机截图
3. 核对是否为最新构建
4. 核对安装时间
5. 重新启动并复测
6. 再决定是代码问题还是安装问题

这样做的目的不是增加流程，而是减少误判和返工。
