# Claude Remote MCP 架构设计

## 1. 文档目的

本文档定义 ToyLink AI 面向 Claude 原对话的 Remote MCP 架构。

最新产品边界和阶段推进以 `docs/22-byo-ai-hardware-connector-roadmap.md` 为准。本文档描述 Claude 作为第一条具体 connector 路径；它不再代表唯一产品方向。

它主要回答 4 个问题：

1. Claude 如何在原对话里调用到 ToyLink 的能力。
2. 为什么不能只靠手机本地 MCP。
3. 远程桥接层、手机 App、本地执行层分别负责什么。
4. 当手机断线、设备断开、验证失效时，系统应该如何表现。

本文档是当前产品主线的正式架构说明，应与以下文档一起理解：

- `CODEX.md`
- `docs/03-mcp-tool-contract.md`
- `docs/04-android-permissions-foreground-service-security.md`
- `docs/16-product-goals-and-next-design-plan.md`

## 2. 当前架构结论

ToyLink AI 的第一条具体 connector 路径采用：

**Claude 原对话 + 公网 Remote MCP Bridge + 手机本地执行**

系统主链路如下：

`Claude 原对话 -> Remote MCP Bridge -> ToyLink App -> SafetyGuard -> ToyDevice -> BLE 玩具`

这里有一个必须坚持的原则：

**聊天和记忆留在 Claude，硬件连接和安全执行留在 ToyLink。**

## 3. 为什么不能只做本地 MCP

当前 Claude 路径的安全 V0 目标是：

- 用户继续在 Claude 原来的那段对话里互动
- Claude 直接在原对话里调用 ToyLink 暴露的安全工具
- 安全 V0 只允许 `get_status` 和 `stop_all`
- 远程刺激控制属于后续门禁阶段

这意味着本地 `localhost` 或局域网 MCP 不能作为首发主路径，原因是：

1. Claude 移动端走的是 Remote MCP，不是手机本地直连。
2. Claude 云端无法直接访问用户手机本地的 `127.0.0.1` 或局域网地址。
3. 即使本地 MCP 能服务某些桌面客户端，它也不能满足“必须保留 Claude 原对话”的首要目标。

因此，首发必须引入 **公网可达的 MCP Bridge**。

## 4. Claude 路径范围与非目标

### 4.1 首发范围

安全 V0 阶段要解决的是：

- 手机连接玩具
- 设备适配器绑定
- 本地低强度验证
- Claude Remote MCP 接入
- Claude 调用 `get_status` 和 `stop_all` 到本地执行的闭环

安全 V0 不开放远程 `set_suck`、`set_vibe`、`set_ems`、`set_all`。

### 4.2 非目标

首发阶段明确不解决：

- 在 ToyLink 内部重新聊天
- 迁移 Claude 的历史记忆
- 将 Claude 路径直接泛化成 GPT / 酒馆 / 自建终端的正式支持
- 复杂多租户平台化运营能力
- 用户自部署 relay 的完整方案

## 5. 架构总览

### 5.1 逻辑分层

系统分为 5 层：

1. `Claude Conversation Layer`
2. `Remote MCP Bridge Layer`
3. `ToyLink Mobile Bridge Client`
4. `ToyLink Local Control Runtime`
5. `BLE Device Layer`

### 5.2 每层职责

#### 1. Claude Conversation Layer

负责：

- 保留原始对话
- 维持记忆和角色关系
- 决定是否调用工具

不负责：

- BLE
- 玩具协议
- 安全上限
- 本地验证

#### 2. Remote MCP Bridge Layer

负责：

- 作为公网可访问的 MCP server
- 向 Claude 暴露工具定义
- 接收工具调用
- 把调用路由到正确的手机会话
- 返回结构化结果

不负责：

- 直接连 BLE
- 解释玩具协议
- 绕过本地安全规则

#### 3. ToyLink Mobile Bridge Client

负责：

- 从手机主动连向桥接层
- 维持设备所属的在线会话
- 接收桥接层下发的工具调用任务
- 将结果回传

不负责：

- 自己决定是否放行不安全命令

#### 4. ToyLink Local Control Runtime

负责：

- `SafetyGuard`
- `ActiveDeviceRegistry`
- `McpToolRouter`
- `ToyDevice`
- 状态读取和错误映射

这是硬件控制的唯一可信执行层。

#### 5. BLE Device Layer

负责：

- 实际与玩具通信
- 执行字节协议
- 返回设备状态

## 6. 关键设计决定

### 6.1 公网入口放在 Bridge，不放在手机端

原因：

- 手机无法稳定提供公网服务
- NAT、运营商网络、系统后台限制都不适合作为服务端入口
- 用户首次配置 connector 时，需要一个稳定地址

因此公网可访问的 MCP 地址应该属于：

`Remote MCP Bridge`

而不是：

- 手机本地 Web server
- 局域网地址
- 临时调试地址

### 6.2 手机对 Bridge 使用主动外连

手机与桥接层的连接方式应为：

- 手机主动建立长连接
- Bridge 不主动打入手机

原因：

- 更适应移动网络与 NAT
- 后台保活策略更清晰
- 更容易做会话恢复

首发阶段推荐方向：

- WebSocket 或等价的双向持久连接

这里文档先定方向，不在本阶段锁死具体库实现。

### 6.3 工具执行必须始终在本地完成

Bridge 可以看到：

- 工具名
- 参数
- 调用结果

但真正执行控制的地方必须是手机本地：

`Bridge -> Mobile Bridge Client -> SafetyGuard -> ToyDevice`

Bridge 不得持有：

- BLE 连接
- 原始协议编码逻辑
- 绕过本地验证的控制能力

### 6.4 安全 V0 采用“单活跃设备 + 单活跃会话”

虽然底层模型可以保留多设备扩展空间，但首发推荐只保证：

- 一个当前活跃设备
- 一个当前活跃 Claude 控制会话

这样可以显著降低复杂度，避免在首发阶段引入多设备路由问题。

## 7. 首发链路拓扑

```text
Claude Original Conversation
-> Remote MCP Connector
-> Remote MCP Bridge
-> Mobile Bridge Session
-> McpToolRouter
-> SafetyGuard
-> Application Use Case
-> ActiveDeviceRegistry
-> ToyDevice
-> BLE Device
```

## 8. 首发会话模型

### 8.1 会话标识

Bridge 侧必须能够区分不同用户手机会话。

安全 V0 的 session 与 token 细则见 `docs/22-byo-ai-hardware-connector-roadmap.md`。正式实现前必须补齐独立的 session / token 生命周期设计。

首发建议引入以下概念：

- `bridgeSessionId`
- `deviceSessionState`
- `connectorToken`

### 8.2 首次绑定流程

推荐绑定流程：

1. 用户在 ToyLink 内完成设备连接和验证
2. App 向 Bridge 申请或刷新一个会话
3. Bridge 返回：
   - connector URL
   - connector token
   - 可用工具说明
4. App 把这些信息展示给用户
5. 用户在 `claude.ai` 完成一次 connector 添加

### 8.3 在线判定

Bridge 应把手机会话状态至少分为：

- `offline`
- `connecting`
- `ready`
- `busy`
- `error`

只有当会话为 `ready`，且本地设备已验证时，才应向用户展示“Claude 可查看状态并急停”。

“Claude 可远程控制刺激输出”必须等后续控制工具安全门禁完成后才能展示。

## 9. 工具调用执行流

### 9.1 正常控制流

安全 V0 正常调用流：

1. Claude 在原对话里决定调用 `get_status` 或 `stop_all`
2. Claude 调用 Remote MCP Bridge
3. Bridge 校验 connector token 和会话状态
4. Bridge 将任务转发到手机会话
5. ToyLink 本地进入 `McpToolRouter`
6. `McpToolRouter` 调用 `SafetyGuard`
7. `SafetyGuard` / AppLock / adapter verification 判断是否允许执行
8. 通过后进入 Application Use Case
9. `ActiveDeviceRegistry` 定位当前活跃设备
10. `ToyDevice` 执行控制
11. 执行结果回传给 Bridge
12. Bridge 返回 Claude

### 9.2 读取状态流

`get_status()` 的处理也应走同样的链路，但它是只读工具：

- 不下发刺激
- 不绕过会话状态检查
- 不要求二次确认

## 10. 安全边界

### 10.1 本地安全链仍是唯一控制前置

即使请求来自 Claude，也不能绕过：

- EMS 上限
- 适配器验证状态
- 设备连接状态
- `stop_all()` 优先级规则
- AppLock 控制边界

### 10.2 EMS 规则不因 Remote MCP 放宽

Remote MCP 不会改变 EMS 规则。

默认规则仍然是：

- `0..8`：可执行
- `9..20`：拒绝并返回需要本地确认
- `>20`：直接拒绝

首发不做远程交互式确认协商。

### 10.3 Bridge 不保存敏感硬件细节

首发建议：

- Bridge 不持久保存完整 BLE 标识
- Bridge 不保存原始字节协议
- Bridge 不保存长期控制历史
- Bridge 不记录亲密场景内容

Bridge 可短期持有最小必要信息：

- 当前会话在线状态
- 最近一次工具调用结果
- 用于诊断的最小错误码

### 10.4 安全 V0 远程工具限制

安全 V0 的 Remote Bridge 工具清单必须固定为：

- `get_status`
- `stop_all`

不得开放 `set_suck`、`set_vibe`、`set_ems`、`set_all`，除非 `docs/22-byo-ai-hardware-connector-roadmap.md` 的 Phase 3 门禁全部满足。

### 10.5 停止能力必须随时可用

无论当前对话或状态如何，都必须确保：

- 本地 App 始终可一键 `stop_all()`
- Remote 工具里的 `stop_all()` 仍优先级最高

## 11. 后台保活要求

首发阶段，手机端必须尽量保证以下事实：

1. App 后台时蓝牙连接尽可能稳定
2. Bridge 会话不断开或可自动恢复
3. 用户能看见当前服务是否仍在线

推荐依赖：

- Android 前台服务
- 明确的通知状态
- App 内桥接状态页

这里要强调：

**前台服务是为了保活和状态透明，不是为了绕过安全规则。**

## 12. 用户可见状态模型

面向普通用户，首发至少要展示以下 4 组状态：

### 12.1 设备状态

- 未连接
- 已连接
- 已断开

### 12.2 适配器状态

- 未绑定
- 已绑定未验证
- 已验证
- 需要重新验证

### 12.3 桥接状态

- 未启动
- 连接中
- 已就绪
- 连接异常

### 12.4 Claude 接入状态

- 尚未配置 connector
- 已可配置
- 配置后待验证
- 当前可控制

## 13. 失败与恢复路径

### 13.1 手机离线

表现：

- Bridge 返回结构化错误
- Claude 看到“当前设备不可达”或等价错误
- App 内状态显示为 `offline`

恢复方式：

- 用户回到 App
- 恢复前台服务/桥接连接
- 不自动恢复刺激输出

### 13.2 玩具断开

表现：

- Bridge 仍在线
- 工具调用返回 `device_disconnected` 或等价错误

恢复方式：

- 用户重新连接玩具
- 不自动恢复上一次强度输出

### 13.3 验证失效

表现：

- Bridge 仍在线
- 控制类工具被拒绝
- `get_status()` 仍可保留只读能力

恢复方式：

- 用户重新进入本地验证流程

### 13.4 后台服务被系统杀死

表现：

- 手机会话转为 `offline`
- Claude 调用失败
- 用户通知或状态页提示失联

恢复方式：

- 用户重新打开 App
- 恢复前台服务
- 重新建立桥接会话

## 14. 与现有文档的关系

### 14.1 本文档覆盖的旧假设

本文档覆盖以下旧假设：

- `docs/03-mcp-tool-contract.md` 中“首发只做 localhost transport”的假设
- `docs/04-android-permissions-foreground-service-security.md` 中“只考虑本地 MCP 暴露”的假设
- 早期“内置聊天可能作为主控制入口”的产品倾向

### 14.2 本文档保留的既有约束

以下约束保持不变：

- `ToyDevice` 抽象边界
- `SafetyGuard` 唯一前置
- `Failure` 统一错误体系
- 低强度验证先于 AI 控制
- `stop_all()` 最高优先级

## 15. 当前开放问题

以下问题在正式编码 Bridge 前仍需定稿：

1. Bridge 是首发官方托管，还是先以受控开发环境形式存在。
2. 手机与 Bridge 之间使用哪种长连接协议。
3. connector token 的发放、刷新和吊销策略如何设计。
4. Claude 接入成功后的验证步骤怎么设计得更新手友好。
5. App Lock 与“已武装的远程控制会话”如何协同。

## 16. 下一步建议

在本文档之后，最值得继续补齐的是两份文档：

1. `docs/20-claude-connector-onboarding-flow.md`
   作用：把首次添加 connector 的用户教程和状态反馈写清楚。

2. `docs/22-byo-ai-hardware-connector-roadmap.md`
   作用：把 BYO-AI 产品边界、安全 V0、验收标准和阶段推进顺序写清楚。

在这两份文档明确前，不建议直接大规模编码 Remote Bridge。
