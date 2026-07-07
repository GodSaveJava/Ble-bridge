# BYO-AI Hardware Connector 边界、验收与推进计划

## 1. 文档地位

本文档是 ToyLink AI 当前阶段的推进准绳。

后续产品、架构、代码、测试和发布工作必须先对齐本文档。若本文档与早期“Claude-only”“本地 MCP 优先”“内置聊天优先”的描述冲突，以本文档为准。

## 2. 产品定义

ToyLink AI 是 **BYO-AI Hardware Connector**。

用户继续使用自己原来的 AI 聊天 Web/App。ToyLink 只负责把“支持工具调用的 AI”安全连接到用户本地硬件。

主链路：

```text
用户自己的 AI 聊天 Web/App
-> AI 平台的工具 / 插件 / Connector 能力
-> ToyLink Bridge
-> ToyLink App
-> SafetyGuard / Adapter Verification
-> BLE 硬件
```

ToyLink 不是聊天替代品，不迁移聊天记录、角色关系或记忆体系。

## 3. 边界条件

- 只支持有工具调用能力的 AI 环境，例如 MCP、OpenAPI / REST tool、function calling、webhook。
- 不通过读屏、浏览器注入、模拟点击、劫持闭源聊天网页来判断 AI 意图。
- Bridge 只转发任务和返回结果，不连接 BLE、不保存原始协议、不绕过 App 本地安全规则。
- 所有硬件控制必须在 ToyLink App 本地经过 `SafetyGuard`、adapter verification、active device resolution 和 AppLock 控制边界。
- Phase 1 / 安全 V0 的远程 Connector 只开放 `get_status` 和 `stop_all`。用户自己的 AI web/app 在此阶段只能查看脱敏状态和触发急停，不能调用任意硬件控制。
- `set_suck`、`set_vibe`、`set_ems`、`set_all` 不得远程开放，除非 Phase 3 门禁满足：安全评审、真机证据、急停优先级验证、能力/范围校验和回滚开关全部完成。
- 当前公网 HTTP Bridge 只允许作为内测环境。正式发布环境必须使用 HTTPS 和 token 鉴权。
- 不上传 BLE 原始 ID、原始控制日志、亲密使用历史。对外返回设备别名或脱敏状态。
- GPT / ChatGPT 支持是后续接入目标之一，但不改变 ToyLink 的定位：优先连接用户已有 AI 环境，而不是把用户迁入 ToyLink 内聊天。

## 4. 安全 V0 验收标准

安全 V0 只有在以下条件全部满足后才算完成：

1. App 可以在 real BLE 模式连接真机，完成 adapter 绑定与低强度验证。
2. Remote Bridge 线上 `/mobile-bridge/session/start` 只返回 `get_status,stop_all`。
3. 非 loopback 的明文 HTTP Bridge 不可作为正式配置启用。
4. Bridge shared token、connector token、debug token 有明确生命周期和鉴权逻辑。
5. `/debug/enqueue` 默认返回 404；启用 debug token 后，无 token 请求返回 401。
6. App 全局 `stop_all` 始终可见，并能抢占普通命令队列。
7. App locked 时远程控制类工具不可执行；V0 只允许 `stop_all` 无条件放行。
8. 用户至少可以在一个原有 AI 聊天环境中完成 connector 配置，并成功调用 `get_status` / `stop_all`。
9. 有当天可复现测试记录：`flutter analyze`、`flutter test`、`cd bridge_server; dart test`。
10. 有真机证据：扫描、连接、验证、急停、后台保活、Bridge 调用截图或日志 manifest。

## 5. 阶段推进计划

### Phase 0: 工程基线恢复

目标：让项目可追踪、可验证、可交接。

- 恢复 git 仓库或重新 clone 正式仓库。
- 修复本机 Flutter / Dart PATH。
- 跑通 `flutter analyze`、`flutter test`、`cd bridge_server; dart test`。
- 建立 `docs/evidence/` 发布证据模板。
- 明确 mock / real BLE 构建开关，并在 App 内显示当前运行模式。

完成标准：任何人能从干净环境拉代码、跑测试，并知道当前 App 是 mock BLE 还是 real BLE。

### Phase 1: 安全 V0

目标：先做可信的“状态 + 急停”Remote Bridge。

- Remote Bridge 改为 HTTPS / token 强制策略。
- Bridge session 和 token 改为随机、不可猜、会话绑定。
- 本地 MCP 加鉴权，避免同设备恶意请求。
- AppLock 接入控制链：locked 时拒绝控制类工具。
- Remote Bridge allowlist 固定为 `get_status,stop_all`。
- 产品文案改成“可查看状态并急停”，不宣称已开放远程刺激控制。
- 接入教程、schema 示例和页面状态不得暗示用户自己的 AI web/app 已能调用 `set_*` 或任意硬件控制。

完成标准：公网内测环境可安全演示 `get_status` 和 `stop_all`，且不能远程调用 `set_*`。

### Phase 2: BYO-AI 接入层

目标：让不同 AI 平台都能接入 ToyLink，但仍只开放安全 V0 工具。

- 在 App 内生成连接卡片，打包 connector URL、token、阶段、安全工具范围和接入说明，减少用户手动搬运配置项。
- 复制连接卡片后进入验证状态，收到首次成功 `get_status` 后自动标记 AI 已连接。
- 支持二维码和 `toylink://connector-card/v1` deep link 导出，让连接卡片可以跨设备搬运；自动导入能力需要单独验收 Android intent / app links。
- MCP Connector 作为首选协议。
- 增加 OpenAPI / REST tool schema，服务不支持 MCP 但支持 HTTP tools 的用户 AI。
- 提供 Claude、ChatGPT / GPT、自建 Agent 三套接入说明。
- 将 Claude onboarding 扩展为通用 AI Connector Setup，并按平台展示步骤。
- 用“首次真实工具调用成功”作为接入完成条件，而不是只靠用户自报。

完成标准：至少两类 AI 环境可接入，一个 MCP 客户端，一个 REST / OpenAPI tool 客户端。

### Phase 3: 低强度控制开放

目标：安全门禁满足后，逐步开放远程 `set_*`。

- 先只开放一个低风险工具，例如 `set_vibe` 或 `set_suck`。
- 强制 adapter verified、active binding、capability / range 校验。
- 合成有效安全策略：全局上限 ∩ 设备上限 ∩ adapter 上限。
- EMS 远程默认继续不开放，除非另行安全评审。
- 控制工具必须有回滚开关，可以一键恢复到安全 V0。

完成标准：真机低强度控制可复现，急停优先级验证通过，失败时不会继续落地旧命令。
在这些门禁满足前，所有用户/开发者接入文档仍必须按 Phase 1 / Safety V0 口径描述：远程只允许 `get_status` 和 `stop_all`。

### Phase 4: GPT / 多平台正式支持

目标：把 GPT 支持纳入正式接入矩阵。

- ChatGPT / GPT 支持优先复用 MCP / connector 路线。
- ToyLink 内置 GPT 如要做，走 OpenAI Responses API + function calling，但作为增强能力，不替代用户原聊天环境。
- 每个平台维护独立接入模板、能力矩阵、故障排查页。
- Bridge 工具能力按平台、用户、设备验证状态动态下发。

完成标准：GPT / ChatGPT、Claude、自建 Agent 至少各有一条清晰可测的接入路径。

### Phase 5: 规模化与发布

目标：从内测演示走向可发布产品。

- HTTPS 域名、证书、日志脱敏、token 轮换、撤销、过期策略完成。
- Android foreground service 真机稳定性通过 10 / 30 / 60 分钟后台测试。
- 发布签名、包名、隐私政策、权限说明完成。
- 建立发布前检查清单和 evidence manifest。
- 明确哪些证据不能进 GitHub，只能私有归档。

完成标准：新用户能按教程完成接入；失败时有可恢复路径；发布证据可复核。

## 6. 当前立即执行顺序

1. 修复 git 与 Flutter / Dart 环境。
2. 将公网 Bridge 从“默认生产 HTTP 地址”降级为“内测配置”。
3. 补充 Remote Bridge session / token 生命周期设计。
4. 修 Android foreground service Manifest 与权限流程。
5. 将首页、MCP 页、AI 接入向导文案改为安全 V0：`get_status + stop_all`。
