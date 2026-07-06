# ToyLink AI 推进计划

## Goal

严格按照 `docs/22-byo-ai-hardware-connector-roadmap.md` 推进 ToyLink AI。

## Current Phase

Phase 0: 工程基线恢复（in progress）。

## Phase Checklist

- [ ] Phase 0: 工程基线恢复
  - [x] 建立并对齐 `docs/22-byo-ai-hardware-connector-roadmap.md`
  - [x] 建立持久计划文件：`task_plan.md`、`findings.md`、`progress.md`
  - [x] 调用工程化角色子智能体完成 DevOps / 安全 / 移动端 / QA 只读审查
  - [x] App 内显示当前硬件模式：Mock BLE / Real BLE
  - [x] 默认 Remote Bridge 不再静默指向公网 HTTP，未显式配置时为 disabled/offline
  - [x] Android main Manifest 补 `INTERNET` 与 foreground service 声明
  - [x] 建立 `docs/evidence/phase-0-1-evidence-manifest-template.md`
  - [x] 补根 README 的干净环境、测试、mock/real BLE、Bridge 联调说明
  - [x] 恢复 Git 仓库、配置 remote，并推送到 `origin/main`
  - [ ] 修复 Flutter / Dart PATH
  - [ ] 跑通并归档 `flutter analyze`
  - [ ] 跑通并归档 `flutter test`
  - [ ] 跑通并归档 `cd bridge_server; dart test`
  - [ ] 建立最小 CI 基线
- [ ] Phase 1: 安全 V0
  - [ ] Remote Bridge 强制 HTTPS / token 策略
  - [ ] Bridge session / connector token 使用 CSPRNG、过期、轮换、会话绑定
  - [ ] Bridge server 固定安全 V0 allowlist：`get_status,stop_all`
  - [ ] `/debug/enqueue` 按 allowlist 校验工具名
  - [ ] 本地 MCP 加鉴权，Phase 1 默认只暴露 `get_status,stop_all`
  - [ ] AppLock 接入控制授权链，locked 时只放行 `stop_all`
  - [ ] 远程 `get_status` / task result 脱敏，不上传 BLE raw id / GATT 指纹
  - [ ] `stop_all` 高优先级抢占路径与测试证据
- [ ] Phase 2: BYO-AI 接入层
- [ ] Phase 3: 低强度控制开放
- [ ] Phase 4: GPT / 多平台正式支持
- [ ] Phase 5: 规模化与发布

## Current Blockers

- 当前 PowerShell 找不到 `flutter` / `dart`，无法运行 Phase 0 自动化验证。
- Git 已恢复并推送到 `origin/main`，当前本地与远端一致，HEAD 为 `0413d91`。
- 没有 2026-07-06 当天测试证据；历史 `docs/evidence/worktree-audit-2026-07-04.md` 不可替代当天验收。
- Phase 1 之前不得开放远程 `set_*`；本地 MCP 当前仍暴露 `set_*`，必须作为安全 V0 高优先级修复。

## Governing Documents

- `docs/22-byo-ai-hardware-connector-roadmap.md`
- `CODEX.md`
- `docs/16-product-goals-and-next-design-plan.md`
- `docs/19-claude-remote-mcp-architecture.md`

## Non-Negotiable Rule

不得开放远程 `set_*` 工具，除非 `docs/22-byo-ai-hardware-connector-roadmap.md` 中 Phase 3 的门禁全部满足。

任何验收结论必须以当天 evidence manifest 为准；缺少工具链、真机或命令输出时只能标记为 `BLOCKED`，不得写成通过。
