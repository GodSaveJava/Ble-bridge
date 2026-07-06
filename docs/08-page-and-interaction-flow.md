# 页面与交互流

## 1. 文档目的

本文件定义 ToyLink AI 第一阶段的页面结构和用户主交互流。

当前产品主线已经明确为：

- 用户在 App 内完成连接与验证
- 外部 AI 通过 MCP 调用 ToyLink

因此第一阶段页面设计应优先服务：

- 配对
- 适配器选择与导入
- 低强度验证
- 手动控制
- MCP 状态与启停

## 2. 页面设计总原则

- 首页负责总览和主入口
- 扫描连接与验证是任务流页面
- 控制页负责手动控制和紧急停止
- MCP 页负责服务状态与接入说明
- 设置页负责安全、隐私和偏好
- 设备管理页负责模板、适配器与分享

第一阶段不把内置聊天作为主入口。

## 3. 页面范围

第一阶段优先页面如下：

1. `Home`
2. `ScanAndPair`
3. `AdapterSetup`
4. `VerificationWizard`
5. `Control`
6. `McpStatus`
7. `DeviceManager`
8. `Settings`
9. `LockOverlay`

## 4. 首页 Home

### 目标

作为用户进入产品后的总控页。

### 主要模块

- 当前设备状态卡片
- MCP 服务卡片
- 一键进入扫描连接
- 最近一次适配器/设备摘要
- 快速入口：
  - 控制页
  - 设备管理
  - 设置

### 关键状态

- `initial`
- `checkingEnvironment`
- `noDevice`
- `deviceConnectedUnverified`
- `deviceVerifiedReady`
- `mcpStopped`
- `mcpRunning`
- `error`

### 不负责什么

- 不直接发 BLE 命令
- 不执行适配器验证逻辑

## 5. 扫描连接页 ScanAndPair

### 目标

完成蓝牙扫描、设备选择和连接。

### 主要模块

- 权限状态提示
- 蓝牙环境状态
- 设备列表
- 连接进度状态

### 关键状态

- `idle`
- `requestingPermissions`
- `bluetoothUnavailable`
- `scanning`
- `resultsAvailable`
- `connecting`
- `connected`
- `scanFailed`
- `connectionFailed`

### 不负责什么

- 不保存适配器验证结果
- 不编码 BLE 协议

## 6. 适配器设置页 AdapterSetup

### 目标

让用户选择模板、导入文件或进入高级模式。

### 主要模块

- 系统推荐模板
- 导入适配器文件
- 高级模式入口
- 静态校验结果

### 关键状态

- `loadingTemplates`
- `templateReady`
- `fileImporting`
- `schemaValid`
- `schemaInvalid`
- `awaitingVerification`

### 不负责什么

- 不直接决定设备已启用
- 不执行最终安全判断

## 7. 验证向导页 VerificationWizard

### 目标

让用户完成低风险试运行，确认适配器可用。

### 主要模块

- 当前步骤说明
- 开始测试按钮
- 用户确认按钮：
  - 有反应且正确
  - 没反应或不正确
- 失败重试与终止

### 默认步骤

- `set_suck(10, mode=1)`
- `set_vibe(10, mode=1)`
- `set_ems(1, mode=1)`
- `stop_all()`

### 关键状态

- `ready`
- `executingStep`
- `awaitingUserConfirmation`
- `stepFailed`
- `verificationPassed`
- `verificationFailed`

### 不负责什么

- 不决定 MCP 放行规则
- 不修改系统级安全上限

## 8. 控制页 Control

### 目标

提供手动控制和紧急停止。

### 主要模块

- 强度滑块
- 模式选择
- 当前状态显示
- `stop_all` 按钮
- EMS 提醒

### 关键状态

- `locked`
- `noActiveDevice`
- `unverifiedDevice`
- `ready`
- `applyingCommand`
- `awaitingEmsConfirmation`
- `stopping`
- `controlError`

### 不负责什么

- 不直接调用 BLE
- 不绕过 `SafetyGuard`

## 9. MCP 状态页 McpStatus

### 目标

告诉用户本地 MCP 是否可用，以及外部 AI 如何接入。

### 主要模块

- 服务开关
- 运行状态
- 当前 endpoint 信息
- 当前可控制设备状态
- 错误说明

### 关键状态

- `stopped`
- `starting`
- `runningWithoutVerifiedDevice`
- `runningWithVerifiedDevice`
- `error`

### 不负责什么

- 不直接执行工具逻辑
- 不负责设备配对

## 10. 设备管理页 DeviceManager

### 目标

管理模板、导入文件和导出分享。

### 主要模块

- 已导入适配器列表
- 当前验证状态
- 导出分享按钮
- 重新验证按钮
- 删除或禁用入口

### 关键状态

- `loading`
- `ready`
- `exporting`
- `importing`
- `reverifyRequired`
- `error`

## 11. 设置页 Settings

### 目标

集中管理安全、隐私和基础偏好。

### 主要模块

- EMS 上限说明
- App Lock
- 隐私设置
- 扫描前缀
- 自动断开策略

### 关键状态

- `loading`
- `ready`
- `saving`
- `saveError`

## 12. 应用锁覆盖层 LockOverlay

### 目标

在敏感页面之上进行阻断，而不是强制切独立锁页。

### 覆盖对象

- `Control`
- `Settings` 的安全区域
- `DeviceManager` 的敏感操作

### 关键状态

- `unlocked`
- `locked`
- `unlocking`
- `unlockFailed`

## 13. MVP 最小用户主路径

1. 打开 App
2. 进入首页
3. 点“扫描连接”
4. 选择目标设备并连接
5. 进入适配器设置页
6. 选择模板或导入适配器文件
7. 跑完验证向导
8. 回到首页看到设备已可用
9. 进入 MCP 页启动本地 MCP
10. 外部 AI 通过 MCP 控制设备
