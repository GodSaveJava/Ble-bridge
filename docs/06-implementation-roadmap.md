# 实施路线图

## 文档目的

这份文档不是讲架构理念，而是把 ToyLink AI 的 MVP 开发过程拆成一条可以照着走的实施路线。

它主要解决三个问题：

- 先做什么，后做什么
- 每一步做到什么程度才算完成
- 哪些事情现在不该做，避免初期把项目做乱

如果你是初级开发者，这份文档可以把“抽象的架构设计”翻译成“具体的开发顺序”。

## 开发总原则

在开始每个阶段前，都要先检查这些原则：

- 先规划，再编码
- 先搭边界，再写细节
- 先打通主链路，再补增强能力
- 先保证安全和可维护，再追求功能数量
- UI 不直接操作 BLE、MCP、存储插件

一句话理解：

先把路修好，再让车跑起来。

## 分阶段实施顺序

ToyLink AI MVP 推荐按以下 7 个阶段推进：

1. `Phase 1: Core + Domain 基础层`
2. `Phase 2: Application 编排层`
3. `Phase 3: BLE + SOSEXY 基础设施`
4. `Phase 4: 设备扫描与手动控制 Feature`
5. `Phase 5: MCP Server Feature`
6. `Phase 6: 聊天壳层 + 设置页`
7. `Phase 7: 收尾与质量保障`

这个顺序是默认推荐顺序，原因是它符合 Clean Architecture 的依赖方向。

## Phase 1: Core + Domain 基础层

### 阶段目标

建立项目的最小骨架，让后续所有功能都建立在统一规则上。

### 要产出的代码和能力

- `core/` 下的常量、主题、基础路由骨架
- `Failure` 基础抽象
- 核心领域实体：
  - `ToyDevice`
  - `ToyDeviceInfo`
  - `DeviceStatus`
  - `ControlCommand`
  - `SafetyPolicy`
- 目录结构从默认 Flutter 模板切换到 Feature-First + Clean Architecture

### 依赖前置条件

- `CODEX.md`
- `docs/02-domain-interfaces-and-state-machines.md`
- `docs/05-storage-and-security-schema.md`

### 阶段完成标准

- 默认 counter 模板思路被清理掉
- 领域接口不再靠后续实现时临时决定
- `Failure` 有明确的顶层分类
- 任何 feature 开发都已经有可依赖的核心类型

### 常见误区

- 一上来先写页面，导致后面类型不停改
- 把 BLE 或平台类型直接写进 domain
- `Failure` 先不定义，后面到处乱抛异常

### 这一阶段为什么重要

这一步像打地基。地基不稳，后面所有页面、协议、MCP 都会跟着摇。

## Phase 2: Application 编排层

### 阶段目标

在 UI 和基础设施之间建立一层“调度中心”，让所有控制和状态流都走统一路径。

### 要产出的代码和能力

- 关键 use case
- `ActiveDeviceRegistry`
- `SafetyGuard`
- 一键启动编排器
- 状态同步协调器
- Riverpod 控制器基础骨架

### 依赖前置条件

- `Phase 1` 完成
- `docs/02-domain-interfaces-and-state-machines.md`
- `docs/07-failure-catalog.md`

### 阶段完成标准

- UI 不需要直接知道设备怎么连、命令怎么发
- MCP 和 UI 都能复用同一套控制逻辑
- EMS 安全校验已经有统一入口

### 常见误区

- 把 Notifier 当成业务逻辑黑洞，所有东西都堆进去
- 直接在 use case 里写具体 BLE 细节
- 为了快，绕过 `SafetyGuard`

### 这一阶段为什么重要

如果说 domain 是规则，application 就是交通指挥。它决定系统是不是“看起来能跑，但其实很乱”。

## Phase 3: BLE + SOSEXY 基础设施

### 阶段目标

把真实硬件控制能力接进系统，但仍然保持协议和业务逻辑的边界干净。

### 要产出的代码和能力

- BLE 扫描与连接适配层
- 服务发现与特征发现
- 写入队列
- `SosexyGattProfile`
- `SosexyProtocolSpec`
- `SosexyProtocolCodec`
- `SosexyDevice`

### 依赖前置条件

- `Phase 1` 和 `Phase 2` 完成
- `docs/01-sosexy-protocol-spec.md`
- `docs/04-android-permissions-foreground-service-security.md`

### 阶段完成标准

- BLE 代码被隔离在 `infrastructure/`
- `SosexyDevice` 可以通过 `ToyDevice` 统一暴露能力
- 命令写入具备串行队列
- `stopAll()` 能高优先级执行

### 常见误区

- 在 widget 或 provider 里直接写 UUID 和字节数组
- 不做写入串行化，导致滑块拖动时写乱
- 把协议细节埋在多个方法里，后面没法改

### 这一阶段为什么重要

这是项目第一次真正接触“硬件的不确定性”。架构如果没守住，后面每加一个设备都会越来越痛苦。

## Phase 4: 设备扫描与手动控制 Feature

### 阶段目标

完成用户第一条最重要的主路径：扫描、连接、手动控制、停止。

### 要产出的代码和能力

- 扫描页
- 设备列表
- 连接状态页或区域
- 手动控制面板
- 停止按钮
- EMS 超限警示和确认 UI

### 依赖前置条件

- `Phase 1` 到 `Phase 3` 完成
- `docs/07-failure-catalog.md`

### 阶段完成标准

- 用户可以完成扫描 -> 连接 -> 控制 -> 停止主路径
- 控制 UI 不直接处理协议细节
- 安全提示在正确的位置出现

### 常见误区

- 为了快，把业务判断塞进 widget
- UI 和设备状态不同步
- 把 EMS 当成普通滑块处理，没有强提醒

### 这一阶段为什么重要

这是 MVP 第一次出现“可体验的产品形态”。哪怕后面 MCP 没接完，这一步做好也已经能验证核心产品价值。

## Phase 5: MCP Server Feature

### 阶段目标

让本地 AI 客户端或后续桥接层能通过统一工具接口控制活跃设备。

### 要产出的代码和能力

- 本地 MCP Server 启停
- tool 注册
- `McpToolRouter`
- MCP 服务状态展示

### 依赖前置条件

- `Phase 2` 到 `Phase 4` 完成
- `docs/03-mcp-tool-contract.md`
- `docs/07-failure-catalog.md`

### 阶段完成标准

- `set_suck`
- `set_vibe`
- `set_ems`
- `set_all`
- `stop_all`
- `get_status`

都能通过统一路径调用，并正确处理失败场景。

### 常见误区

- 直接在 tool handler 里写 BLE 调用
- 忘记对 EMS 做和 UI 一致的安全限制
- 设备掉线时直接让 MCP 服务崩掉

### 这一阶段为什么重要

这是 ToyLink AI 和普通 BLE App 最大的差异点。它决定我们是不是一款真正支持 AI 控制的产品。

## Phase 6: 聊天壳层 + 设置页

### 阶段目标

补齐用户体验层，让产品从“功能能跑”变成“用户能理解、能配置、能使用”。

### 要产出的代码和能力

- 聊天消息列表 UI
- 工具调用记录展示
- `ChatProvider` 的本地壳层实现
- 设置页
- App Lock
- 扫描前缀、自定义设置、自动断开开关

### 依赖前置条件

- 前五个阶段完成
- `docs/05-storage-and-security-schema.md`
- `docs/04-android-permissions-foreground-service-security.md`

### 阶段完成标准

- 聊天模块即使不接真实模型，也有稳定的会话骨架
- 设置项已经有清晰存储落点
- 安全和隐私功能开始形成完整体验

### 常见误区

- 聊天模块一开始就强耦合某个模型 API
- 设置页直接操作存储插件
- App Lock 只做 UI 假锁，不影响敏感操作路径

### 这一阶段为什么重要

这是把“工程原型”推进成“产品原型”的阶段。

## Phase 7: 收尾与质量保障

### 阶段目标

把项目从“基本能用”提升到“可以稳定演示和继续迭代”。

### 要产出的代码和能力

- 单元测试补齐
- Widget 测试补齐
- 权限文案与错误提示整理
- 日志脱敏
- 文档与代码自检

### 依赖前置条件

- 前六个阶段完成
- 所有核心设计文档稳定

### 阶段完成标准

- 核心主路径可演示
- 主要失败场景有统一表现
- 关键安全规则没有被绕过
- 代码结构仍符合 `CODEX.md`

### 常见误区

- 功能写完就算完成，不补测试
- 只测成功路径，不测失败路径
- 为了赶进度，开始跨层偷写逻辑

### 这一阶段为什么重要

如果没有这一步，前面所有工作都容易在第一次联调或第一次需求变更时崩掉。

## 阶段间依赖关系

推荐依赖顺序如下：

- `Phase 1` 是所有阶段的基础
- `Phase 2` 依赖 `Phase 1`
- `Phase 3` 依赖 `Phase 1 + Phase 2`
- `Phase 4` 依赖 `Phase 1 + Phase 2 + Phase 3`
- `Phase 5` 依赖 `Phase 2 + Phase 3 + Phase 4`
- `Phase 6` 依赖前五个阶段
- `Phase 7` 依赖全部前置阶段

## MVP 最小验收路径

如果只验证 MVP 是否成型，最小验收路径是：

1. 用户打开 App
2. 允许蓝牙相关权限
3. 扫描到 SOSEXY 设备
4. 成功连接
5. 手动调节 suck 或 vibe
6. `stopAll()` 生效
7. 启动本地 MCP Server
8. 通过 MCP 调用 `get_status`
9. 通过 MCP 调用 `set_suck`
10. EMS 超限请求被正确拦截

## 给初级开发者的建议

如果你不知道当前该做什么，就按这条思路判断：

- 先看当前阶段目标
- 再看该阶段完成标准
- 最后看常见误区，避免一开始就走偏

不要同时跨多个阶段乱写。一步一步来，反而更快。
