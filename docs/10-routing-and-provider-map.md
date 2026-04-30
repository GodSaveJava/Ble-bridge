# 路由与 Provider 映射设计

## 文档目的

这份文档把 ToyLink AI 已有的设计文档进一步翻译成 Flutter 实现层能直接落地的结构说明。

它主要解决以下问题：

- 哪些页面对应哪些 route
- 哪些页面依赖哪些 Riverpod provider
- 哪些 provider 是共享能力，哪些只是页面组合层
- 锁屏覆盖层怎么接入
- 混合导航模式下，页面和状态怎样保持清晰

如果前面的页面文档解决的是“页面要做什么”，那么这份文档解决的就是：

“这些页面在 Flutter 里该怎么挂起来，状态该怎么接进去。”

## 路由设计总原则

ToyLink AI MVP 的路由设计必须遵守以下原则：

- 路由负责页面进入关系，不负责业务控制逻辑
- provider 负责状态，不负责视觉布局
- 页面不拥有系统真相状态，只消费 provider
- 共享状态尽量按能力建模，不按页面复制
- 锁屏优先作为 UI 覆盖层，而不是默认强制跳独立路由
- 混合导航必须避免页面能跳得动，但状态来源一团乱

一句话总结：

路由决定“去哪里”，provider 决定“看到什么状态”，业务逻辑则应继续待在 application 和 domain 中。

## 为什么采用混合导航模式

你已经确认 MVP 采用“混合导航模式”，而不是纯首页跳转或纯底部导航。

这样做的主要原因是：

- 首页、控制、聊天、设置属于高频页面，适合放在主导航结构中
- 扫描连接更像任务流，不适合长期占据底部导航位
- MCP 作为核心能力需要明显入口，但又不等于主日常浏览页
- 安全覆盖层要尽量不打断当前页面上下文

## 默认导航结构

MVP 建议使用以下结构：

### 根级宿主

- `AppShell`
- `HomeShell`
- `LockOverlayHost`

### 底部导航主区

建议放入底部导航的页面：

- `HomePage`
- `ControlPage`
- `ChatPage`
- `SettingsPage`

### 独立 push 页面

建议保持独立 route 的页面：

- `ScanPage`
- `McpPage`
- `McpStatusPage`
- `DeviceManagerPage` 预留
- `SecuritySettingsPage` 预留

### 这样设计的好处

- 高频页面切换成本低
- 扫描和 MCP 状态页仍能保持任务流语义
- 锁层覆盖时不用销毁当前页面
- Provider 更容易围绕能力复用

## 路由清单

MVP 推荐至少定义以下 route：

- `/`
- `/home`
- `/control`
- `/chat`
- `/settings`
- `/scan`
- `/mcp`
- `/mcp/status`
- `/device-manager`
- `/settings/security`

## 路由角色说明

### `/`

- App 入口
- 用于进入 `AppShell`
- 决定初始加载和宿主结构

### `/home`

- 主首页
- 用户默认进入页
- 显示设备状态、MCP 状态、一键启动和快速导航

### `/control`

- 手动控制主页面
- 属于底部导航高频页

### `/chat`

- 聊天壳层页面
- 属于底部导航高频页

### `/settings`

- 设置主页面
- 属于底部导航高频页

### `/scan`

- 扫描连接页
- 任务流页面
- 建议独立 push 进入

### `/mcp`

- MCP 服务入口页
- 从首页主卡片进入

### `/mcp/status`

- MCP 服务状态详情页
- 用于更清晰展示服务运行情况和问题说明

### `/device-manager`

- 预留给未来设备模板管理和扩展

### `/settings/security`

- 预留给未来更细的安全设置页

## App Lock 的路由定位

MVP 默认不使用独立 `/lock` 作为主要方案。

默认策略是：

- 使用 `LockOverlayHost`
- 对敏感页面进行覆盖式阻断
- 解锁成功后恢复原上下文

这样做的原因：

- 不打断当前页面流程
- 不需要频繁重新建页面
- 用户感知更连贯

## Provider 组织方式

你已经明确选择“按能力分层”，所以 provider 不按页面堆，而按系统能力拆分。

这意味着：

- 首页不会拥有一整套只属于首页的设备状态真相
- 控制页不会复制一份活跃设备状态
- 聊天页不会单独维护另一套 MCP 服务状态

## 核心 Provider 分组

### 环境与权限

- `bluetoothEnvironmentProvider`
- `permissionStatusProvider`

作用：

- 提供蓝牙环境是否可用
- 提供权限是否满足当前流程

### 设备扫描与连接

- `scanControllerProvider`
- `scanResultsProvider`
- `connectionControllerProvider`

作用：

- 启动和停止扫描
- 暴露扫描结果
- 负责连接流程状态

### 活跃设备与控制

- `activeDeviceProvider`
- `activeDeviceStatusProvider`
- `controlPanelControllerProvider`
- `safetyGuardProvider`

作用：

- 提供当前活跃设备
- 提供当前设备状态
- 处理控制页动作编排
- 统一执行安全校验

### MCP

- `mcpServiceProvider`
- `mcpStatusProvider`
- `mcpEndpointProvider`

作用：

- 启停 MCP 服务
- 暴露 MCP 当前状态
- 暴露端口和本地访问信息

### 聊天

- `chatSessionProvider`
- `chatMessagesProvider`
- `toolInvocationFeedProvider`

作用：

- 提供聊天会话壳层状态
- 提供消息流
- 提供工具调用记录流

### 安全与锁屏

- `appLockStateProvider`
- `unlockControllerProvider`

作用：

- 提供锁定状态
- 负责解锁动作和恢复流程

### 设置与偏好

- `settingsProvider`
- `scanPrefixProvider`
- `privacySettingsProvider`

作用：

- 提供设置总览
- 管理用户扫描前缀
- 管理隐私和安全相关偏好

## 页面与 Provider 映射

这是这份文档最重要的部分。

### HomePage

依赖：

- `bluetoothEnvironmentProvider`
- `permissionStatusProvider`
- `activeDeviceProvider`
- `activeDeviceStatusProvider`
- `mcpStatusProvider`
- `appLockStateProvider`

页面职责：

- 聚合总览信息
- 不拥有底层真相状态

说明：

首页应该消费多个能力型 provider，而不是自己复制一份系统状态。

### ScanPage

依赖：

- `permissionStatusProvider`
- `scanControllerProvider`
- `scanResultsProvider`
- `connectionControllerProvider`

页面职责：

- 发起扫描
- 展示结果
- 发起连接

说明：

扫描页是任务流页面，不应该长期保留复杂状态副本。

### ControlPage

依赖：

- `activeDeviceProvider`
- `activeDeviceStatusProvider`
- `controlPanelControllerProvider`
- `safetyGuardProvider`
- `appLockStateProvider`

页面职责：

- 展示控制交互
- 发起控制动作
- 等待安全确认 UI

说明：

控制页可以组合状态，但不负责协议编码和最终安全判断。

### McpPage

依赖：

- `mcpServiceProvider`
- `mcpStatusProvider`
- `mcpEndpointProvider`
- `activeDeviceProvider`

页面职责：

- 展示服务状态
- 启停 MCP
- 告知当前是否已有设备可路由

说明：

MCP 页面展示系统能力，不直接执行工具逻辑。

### ChatPage

依赖：

- `chatSessionProvider`
- `chatMessagesProvider`
- `toolInvocationFeedProvider`
- `mcpStatusProvider`
- `activeDeviceProvider`
- `appLockStateProvider`

页面职责：

- 展示聊天壳层
- 展示工具调用记录
- 根据系统状态提示服务可用性

说明：

聊天页必须能消费 MCP 和活跃设备状态，但不应该重建一套控制逻辑。

### SettingsPage

依赖：

- `settingsProvider`
- `privacySettingsProvider`
- `scanPrefixProvider`
- `appLockStateProvider`

页面职责：

- 展示和修改配置
- 不直接操作底层存储插件

## 页面级 Controller 规则

因为 provider 按能力分层，页面级 controller 不应该泛滥。

默认规则如下：

- 核心共享状态使用能力型 provider
- 页面如果只是组合多个状态，不新增重型 page provider
- 只有页面存在明显独立编排流程时，才增加 page-level controller

## 推荐页面级 Controller

### `HomePageController`

允许存在。

作用：

- 聚合首页摘要状态
- 协调一键启动按钮的展示和行为

原因：

首页是组合型页面，适合有一个轻量 controller 做汇总。

### `ScanPageController`

默认不必单独存在。

原因：

- 扫描和连接的核心逻辑已经由能力型 provider 承担
- 页面主要是组合和展示

只有当后续扫描页交互变得明显复杂时，才考虑增加。

### `ControlPageController`

可以存在，但应保持轻量。

作用：

- 管理控制页局部交互态
- 协调 EMS 确认 UI 展示

不能做的事：

- 不接管协议编码
- 不替代 `SafetyGuard`
- 不直接写设备命令

## 锁屏覆盖层接入方式

App Lock 默认采用页面覆盖层。

### 默认行为

- 锁层作为顶层覆盖层注入宿主
- 被覆盖页面保留原状态
- 用户交互被阻断
- 解锁成功后恢复当前上下文

### 适合启用锁层的页面

- `ControlPage`
- `ChatPage`
- `SettingsPage` 中安全相关区域
- 未来的设备管理编辑页

### 为什么不用独立锁页

主要原因：

- 不打断当前上下文
- 不需要频繁跳转
- 用户恢复操作更自然

### 边界提醒

锁层不是业务安全规则的替代品。

即使页面解锁成功：

- `SafetyGuard` 仍然要继续生效
- EMS 上限规则仍然要继续生效
- MCP 调用校验仍然要继续生效

## 路由与 Failure 的关系

`Failure` 不应该直接控制 route，但会影响页面显示和引导行为。

### 推荐映射方式

- `permissionDenied`
  - 扫描页显示权限引导
  - 不强制离开当前页面
- `noActiveDevice`
  - 控制页显示空状态
  - 引导去 `/scan`
- `securityLock`
  - 当前页面挂起
  - 展示锁屏覆盖层
- `mcpServer`
  - 首页或 MCP 页面显示错误态
  - 不强制跳转

这样做的好处是：

- 错误处理不会和路由耦合过死
- UI 可以更自然地表达恢复路径

## 与现有文档的衔接关系

这份文档必须遵守以下已有设计：

- `docs/02-domain-interfaces-and-state-machines.md`
  - provider 状态不能背离核心状态机
- `docs/06-implementation-roadmap.md`
  - route 和 provider 引入顺序要符合开发阶段
- `docs/07-failure-catalog.md`
  - 错误态表达和锁层介入必须一致
- `docs/08-page-and-interaction-flow.md`
  - 页面职责和页面状态必须一致
- `docs/09-testing-strategy.md`
  - provider 和页面映射应便于测试和 Fake 替换
- `CODEX.md`
  - 不得绕过 Clean Architecture 和硬件抽象边界

## MVP 最小实现建议

如果后续开始真正写 Flutter 代码，建议最先落地这些部分：

1. route 基础结构：
   - `/home`
   - `/scan`
   - `/control`
   - `/mcp`
   - `/chat`
   - `/settings`
2. 核心 provider：
   - `activeDeviceProvider`
   - `activeDeviceStatusProvider`
   - `scanControllerProvider`
   - `mcpStatusProvider`
   - `appLockStateProvider`
3. 首页组合逻辑：
   - `HomePageController`

原因：

- 这样可以最早把页面、状态和业务边界接起来
- 也是最适合 MVP 逐步推进的最小骨架

## 给初级开发者的建议

如果你后面写 Flutter 页面时不知道某个状态该放在哪里，可以按下面顺序判断：

1. 这是系统共享状态吗？
2. 这是某个能力的状态吗？
3. 这只是页面局部展示状态吗？

如果答案分别是：

- 是共享状态 -> 放能力型 provider
- 是能力状态 -> 放对应 controller/provider
- 只是页面临时展示 -> 放页面局部状态

不要一上来就给每个页面都造一个很重的 provider。

## 总结

这份文档的核心目的，是把“页面设计”真正翻译成“Flutter 可以实现的结构”。

它要确保我们后面写代码时：

- route 不乱
- provider 不乱
- 锁屏不乱
- 页面和业务边界不乱

只要把这一步搭好，后面的 `go_router` 和 Riverpod 实现就会顺很多。
