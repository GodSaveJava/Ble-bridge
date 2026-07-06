# ToyLink AI Findings

## 2026-07-06

- 产品定位已收敛为 BYO-AI Hardware Connector：连接用户已有 AI 聊天环境与本地硬件，而不是替代聊天。
- 安全 V0 只开放 `get_status` 和 `stop_all`。
- 当前 HTTP 公网 Bridge 只能作为内测环境；正式环境必须迁移到 HTTPS。
- 后续 GPT / ChatGPT 支持应作为接入矩阵的一部分，不改变“用户继续使用原有 AI 环境”的定位。
- 当前首要风险：公网 HTTP、token 生命周期不完整、foreground service 真机风险、本地 MCP 无鉴权、缺少当天可复现测试与真机证据。
- DevOps 审查：当前目录不是 Git 仓库，缺少 `.git`，无法确认 remote/branch/commit；Flutter/Dart 不在 PATH，`flutter analyze`、`flutter test`、`cd bridge_server; dart test` 当前阻塞；未发现 CI 配置，根 README 交接入口不足。
- QA 审查：`test/` 与 `bridge_server/test/` 覆盖面较广，但没有 2026-07-06 当天可复现测试记录；`docs/evidence/` 有历史文件但缺少可发布的真机证据 manifest。
- 安全审查：默认公网 HTTP Bridge、可预测 session/token、本地 MCP 无鉴权并暴露 `set_*`、AppLock 未进入控制授权链、远程 `get_status` 可能上传 BLE raw id，都是 Phase 1 前必须处理的高风险。
- 移动端审查：`TOYLINK_USE_REAL_BLE` 开关已存在，但 App 原先未显示当前 BLE 模式；Android main Manifest 原先缺 `INTERNET` 与 foreground service `<service>` 声明。
- 本轮已将默认 Remote Bridge 从公网 HTTP 回落改为 disabled/offline；显式 saved config 或 dart-define 仍可启用真实 Bridge，后续 Phase 1 需要继续补 HTTPS + token 强制校验。
