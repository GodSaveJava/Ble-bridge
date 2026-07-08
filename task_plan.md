# ToyLink AI 推进计划

## Goal

严格按照 `docs/22-byo-ai-hardware-connector-roadmap.md` 和工程化团队流程推进 ToyLink AI。

ToyLink AI 当前定位为 **BYO-AI Hardware Connector**：用户继续使用自己的 AI Web/App，ToyLink 负责把支持工具调用的 AI 安全连接到本地 BLE 硬件。

## Current Phase

Phase 1：安全 V0（软件侧安全基线已完成，真机证据采集中）。

Phase 0 已完成代码/测试/CI 基线；Android cmdline-tools 已补齐，Android debug APK 可构建。真机 BLE 证据和正式发布安全门禁仍未完成，不能发布。

## Phase Checklist

- [x] Phase 0：工程基线恢复
  - [x] 建立并对齐 `docs/22-byo-ai-hardware-connector-roadmap.md`
  - [x] 建立持久计划文件：`task_plan.md`、`findings.md`、`progress.md`
  - [x] 完成 DevOps / 安全 / 移动端 / QA 只读审查
  - [x] App 内显示当前硬件模式：Mock BLE / Real BLE
  - [x] 默认 Remote Bridge 不再静默指向公网 HTTP，未显式配置时为 disabled/offline
  - [x] Android main Manifest 补齐 `INTERNET` 和 foreground service 声明
  - [x] 建立 `docs/evidence/phase-0-1-evidence-manifest-template.md`
  - [x] 补根 README 的环境、测试、mock/real BLE、Bridge 联调说明
  - [x] 恢复 Git 仓库、配置 remote，并推送到 `origin/main`
  - [x] 修复 Flutter / Dart PATH：用户 PATH 已包含 `C:\Users\NPC\dev\flutter\bin`
  - [x] 跑通并归档 `flutter analyze`
  - [x] 跑通并归档 `flutter test`
  - [x] 跑通并归档 `cd bridge_server; dart test`
  - [x] 建立最小 CI 基线：Flutter analyze/test + bridge server dart test
- [ ] Phase 1：安全 V0
  - [x] Remote Bridge 强制 HTTPS / token 策略
  - [x] Bridge session / connector token 使用 CSPRNG、过期、轮换、会话绑定
  - [x] Bridge server 固定安全 V0 allowlist：`get_status,stop_all`
  - [x] `/debug/enqueue` 按 allowlist 校验工具名，默认关闭且 token 鉴权
  - [x] 本地 MCP 加鉴权，Phase 1 默认只暴露 `get_status,stop_all`
  - [x] AppLock 接入控制授权链，locked 时只放行 `stop_all`
  - [x] 远程 `get_status` / task result 脱敏，不上传 BLE raw id / GATT 指纹
  - [x] `stop_all` 高优先级抢占路径与测试证据
  - [x] 更新面向用户的 BYO-AI Connector 接入文档，避免暗示远程 `set_*` 已开放
  - [x] Android cmdline-tools / SDK 修复，`flutter build apk --debug` 通过
  - [ ] 真机 BLE 扫描、连接、adapter verification、急停与后台保活证据
- [ ] Phase 2：BYO-AI 接入层
  - [x] MVP 连接卡片：把 connector URL、token、Safety V0 工具范围打包为一键复制配置
  - [x] 连接卡片验证流：等待 AI 调用 `get_status` 后自动标记接入成功
  - [x] 二维码 / deep link 导出：用于跨设备搬运连接卡片
  - [x] Android deep link 导入：从 `toylink://connector-card/v1` 打开并预填连接卡片
  - [x] 多平台模板：Claude、ChatGPT / GPT Actions、OpenAPI、Webhook
  - [x] REST / OpenAPI tool 客户端 smoke 证据：从生成 schema 发起真实 `get_status` HTTP 调用
  - [x] MCP 客户端 live evidence：发现 `/mcp/tools` 并通过 `/mcp/call` 调用 `get_status`
  - [x] 通用 AI Connector Setup 页面化：按平台展示 Claude、ChatGPT / GPT Actions、OpenAPI / REST Tool、Webhook 模板
  - [ ] 外部平台手工证据：至少一个 ChatGPT / Claude / 其他用户自有 AI 工具调用环境
- [ ] Phase 3：低强度控制开放
- [ ] Phase 4：GPT / 多平台正式支持
- [ ] Phase 5：规模化与发布

## Current Blockers / Warnings

- 当前 Codex 进程没有继承新的用户 PATH；新 PowerShell 或重启 Codex 后应能直接找到 `flutter` / `dart`。
- `flutter doctor -v` Android toolchain 已通过；仅剩 Windows desktop Visual Studio 缺失和当前进程 PATH 提示，不阻塞 Android。
- `flutter build apk --debug` 当前可通过，但会提示 Kotlin Gradle Plugin 未来版本兼容警告，需要后续依赖/Gradle 迁移跟踪。
- 没有 2026-07-06 真机 BLE 扫描、连接、adapter verification、急停、后台保活证据。
- Phase 1 软件侧安全基线已通过，包含 `stop_all` 远程/MCP 端到端抢占测试；Android debug APK 可构建；真机 BLE 与 Android 后台保活证据仍缺失。

## Governing Documents

- `docs/22-byo-ai-hardware-connector-roadmap.md`
- `CODEX.md`
- `docs/evidence/2026-07-06-phase-0-baseline-evidence.md`
- `docs/evidence/2026-07-06-phase-1-safety-v0-evidence.md`
- `docs/evidence/2026-07-07-phase-2-rest-openapi-connector-evidence.md`
- `docs/evidence/2026-07-08-phase-2-mcp-client-evidence.md`
- `docs/evidence/2026-07-08-phase-2-generic-ai-connector-setup-evidence.md`
- `docs/evidence/phase-0-1-evidence-manifest-template.md`
- `docs/16-product-goals-and-next-design-plan.md`
- `docs/19-claude-remote-mcp-architecture.md`

## Non-Negotiable Rule

不得开放远程 `set_*` 工具，除非 `docs/22-byo-ai-hardware-connector-roadmap.md` 中 Phase 3 的门禁全部满足。

任何验收结论必须以当天 evidence manifest 为准；缺少工具链、真机或命令输出时只能标记为 `BLOCKED`，不得写成通过。

## Next Execution Order

1. 接入 Android 真机，开启 USB 调试后采集 ADB 设备识别证据。
2. 安装 debug APK，切换 Real BLE，采集扫描、连接、adapter verification、急停与后台保活证据。
3. 全量回归后再评估 Phase 1 是否可判 PASS。
4. 继续扩展 Phase 2：外部平台手工证据。
