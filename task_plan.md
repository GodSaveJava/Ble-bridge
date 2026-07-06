# ToyLink AI 推进计划

## Goal

严格按照 `docs/22-byo-ai-hardware-connector-roadmap.md` 和工程化团队流程推进 ToyLink AI。

ToyLink AI 当前定位为 **BYO-AI Hardware Connector**：用户继续使用自己的 AI Web/App，ToyLink 负责把支持工具调用的 AI 安全连接到本地 BLE 硬件。

## Current Phase

Phase 1：安全 V0（准备开始）。

Phase 0 已完成代码/测试/CI 基线，但 Android cmdline-tools、真机 BLE 证据和正式发布安全门禁仍未完成，不能发布。

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
  - [ ] Remote Bridge 强制 HTTPS / token 策略
  - [ ] Bridge session / connector token 使用 CSPRNG、过期、轮换、会话绑定
  - [ ] Bridge server 固定安全 V0 allowlist：`get_status,stop_all`
  - [ ] `/debug/enqueue` 按 allowlist 校验工具名，默认关闭且 token 鉴权
  - [ ] 本地 MCP 加鉴权，Phase 1 默认只暴露 `get_status,stop_all`
  - [ ] AppLock 接入控制授权链，locked 时只放行 `stop_all`
  - [ ] 远程 `get_status` / task result 脱敏，不上传 BLE raw id / GATT 指纹
  - [ ] `stop_all` 高优先级抢占路径与测试证据
  - [ ] 更新面向用户的 BYO-AI Connector 接入文档，避免暗示远程 `set_*` 已开放
- [ ] Phase 2：BYO-AI 接入层
- [ ] Phase 3：低强度控制开放
- [ ] Phase 4：GPT / 多平台正式支持
- [ ] Phase 5：规模化与发布

## Current Blockers / Warnings

- `flutter doctor -v` 仍提示 Android cmdline-tools 缺失；真机 Android 构建和 BLE 实测前必须补齐。
- 当前 Codex 进程没有继承新的用户 PATH；新 PowerShell 或重启 Codex 后应能直接找到 `flutter` / `dart`。
- 没有 2026-07-06 真机 BLE 扫描、连接、adapter verification、急停、后台保活证据。
- Phase 1 之前不得开放远程 `set_*`；本地 MCP 当前仍有控制类工具，必须在安全 V0 中加鉴权和默认暴露限制。

## Governing Documents

- `docs/22-byo-ai-hardware-connector-roadmap.md`
- `CODEX.md`
- `docs/evidence/2026-07-06-phase-0-baseline-evidence.md`
- `docs/evidence/phase-0-1-evidence-manifest-template.md`
- `docs/16-product-goals-and-next-design-plan.md`
- `docs/19-claude-remote-mcp-architecture.md`

## Non-Negotiable Rule

不得开放远程 `set_*` 工具，除非 `docs/22-byo-ai-hardware-connector-roadmap.md` 中 Phase 3 的门禁全部满足。

任何验收结论必须以当天 evidence manifest 为准；缺少工具链、真机或命令输出时只能标记为 `BLOCKED`，不得写成通过。

## Next Execution Order

1. Phase 1 threat model：列出 Remote Bridge、本地 MCP、AppLock、token、debug route 的攻击面。
2. Bridge server allowlist 固定为 `get_status,stop_all`，并补测试。
3. `/debug/enqueue` 默认关闭，启用后要求 debug token，并拒绝非 allowlist 工具。
4. 本地 MCP 加鉴权与默认工具暴露限制。
5. AppLock 接入远程/本地控制授权链：locked 只允许 `stop_all`。
6. `get_status` / task result 脱敏。
7. `stop_all` 抢占路径补强并归档证据。
