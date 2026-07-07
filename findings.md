# ToyLink AI Findings

## 2026-07-06

- 产品定位已收敛为 **BYO-AI Hardware Connector**：连接用户已有 AI 聊天环境与本地硬件，而不是替代聊天产品。
- 只支持有明确工具调用能力的 AI 环境：MCP、OpenAPI / REST tools、function calling、webhook。
- 不做读屏、浏览器注入、模拟点击、劫持闭源聊天网页来推断 AI 意图。
- 安全 V0 只允许 `get_status` 和 `stop_all`。
- `set_suck`、`set_vibe`、`set_ems`、`set_all` 不得远程开放，除非 Phase 3 的安全评审、真机证据和回滚开关全部完成。
- 当前公网 HTTP Bridge 只能作为内测环境；正式环境必须迁移到 HTTPS + token。
- GPT / ChatGPT 支持应作为接入矩阵的一部分，不改变“用户继续使用原有 AI 环境”的定位。
- Phase 0 自动化验证已通过：`flutter analyze`、`flutter test`、`bridge_server dart test` 均为 PASS。
- 最小 CI 已建立：`.github/workflows/ci.yml` 覆盖 Flutter analyze/test 和 bridge server dart test。
- Flutter 3.44.4 下 `CupertinoPageTransitionsBuilder` 需要显式引入 `package:flutter/cupertino.dart`；已修复。
- 用户级 PATH 已包含 `C:\Users\NPC\dev\flutter\bin`；当前 Codex 进程没有继承，需要重启或在命令中显式重载 PATH。
- Android cmdline-tools 已补齐到 `C:\Users\NPC\AppData\Local\Android\Sdk`；`flutter doctor -v` Android toolchain 已通过。
- `flutter build apk --debug` 已通过，产物为 `build\app\outputs\flutter-apk\app-debug.apk`。
- 当前 ADB 没有检测到 Android 真机，Flutter 也没有可用 AVD；真机 BLE 验证仍需用户连接设备并打开 USB 调试。
- 仍缺少当天真机证据：扫描、连接、adapter binding、低强度验证、急停、后台保活、Bridge 调用截图或日志 manifest。
- 用户配置流程的第一轮简化已落地为 MCP 页连接卡片：用户可以一键复制结构化 connector 配置，不再分别搬运 URL、token 和工具范围。
- 安全高风险仍集中在 Phase 1：HTTPS/token、token 生命周期、本地 MCP 鉴权、AppLock 授权链、debug route、远程结果脱敏。
- Phase 1 自动化安全基线已落地：Bridge server allowlist/debug token、非 loopback HTTPS+token、CSPRNG session/token、session TTL/client binding、本地 MCP token、AppLock 授权链、远程结果脱敏均有测试覆盖。
- `stop_all` 远程/MCP 端到端抢占证据已补：远程 `/mobile-bridge/tool-call` 可触发设备层 stop 包，并 supersede pending 非 stop 写入。
- 用户接入文档已收紧为 Phase 1 / Safety V0 口径：远程只开放 `get_status` 和 `stop_all`，不得暗示 `set_*` 已开放。
- Phase 1 仍不能整体判 PASS：缺真机 BLE 证据和 Android 后台保活证据。

## Review Notes

- DevOps：Git 已恢复并推送到 GitHub；CI 基线已补齐，但 Android SDK 环境仍需修。
- QA：自动化测试已有基础，Phase 1 必须继续把安全门禁转成可重复测试。
- Security：外部入口、debug route、本地 MCP 和 token 生命周期必须安全左移，不能等发布前补。
- Mobile：Mock/Real BLE 可见性已补，但真机 BLE 稳定性和 foreground service 还需要实测证据。
