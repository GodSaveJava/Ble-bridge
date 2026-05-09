# Failure 目录

## 1. 文档目的

本文件定义 ToyLink AI 的统一错误语言。

它要保证以下几层看到的是“同一个错误”，只是表现形式不同：

- application
- UI
- MCP
- 日志

## 2. 设计原则

- 全项目只保留一套主错误抽象：`Failure`
- 不把插件原始异常直接暴露给 UI
- 错误要帮助恢复，而不只是报错
- UI 与 MCP 使用同一套错误事实
- 日志保留排查价值，但不能泄露隐私

## 3. 顶层分类

第一阶段推荐使用以下 `Failure.code`：

- `validation`
- `permissionDenied`
- `bluetoothUnavailable`
- `scanFailed`
- `deviceNotFound`
- `deviceConnection`
- `deviceDisconnected`
- `deviceWrite`
- `protocolUnsupported`
- `noActiveDevice`
- `adapterSchemaInvalid`
- `adapterNotVerified`
- `adapterConflict`
- `adapterVerificationFailed`
- `adapterRevoked`
- `mcpServer`
- `storage`
- `securityLock`
- `unknown`

## 4. 通用字段

每个 `Failure` 至少包含：

- `code`
- `message`
- `recoverable`
- `details`
- `source`
- `debugMessage`

## 5. 重点 Failure 说明

### validation

- 含义：输入参数不合法
- 场景：强度越界、模式错误、MCP 参数结构错误
- UI：表单或操作提示
- MCP：`validation_failed`

### permissionDenied

- 含义：缺少蓝牙、通知等权限
- 场景：扫描前未授权
- UI：引导去设置页授权
- MCP：`validation_failed`

### bluetoothUnavailable

- 含义：蓝牙关闭或设备不支持
- UI：阻断提示
- MCP：`device_disconnected`

### deviceConnection

- 含义：连接建立失败
- UI：显示重连
- MCP：`device_disconnected`

### deviceDisconnected

- 含义：设备已断开
- UI：控制页禁用并提示重新连接
- MCP：`device_disconnected`

### deviceWrite

- 含义：命令写入失败
- 场景：超时、特征不可写、队列中断
- UI：提示重试或重连
- MCP：`device_disconnected`

### protocolUnsupported

- 含义：当前设备与协议模板不兼容
- UI：提示切换模板或重新选择设备
- MCP：`validation_failed`

### noActiveDevice

- 含义：没有活跃设备
- UI：引导去扫描页
- MCP：`no_active_device`

### adapterSchemaInvalid

- 含义：适配器文件结构不合法
- 场景：缺字段、字段类型错误、版本不兼容
- UI：导入失败并提示文件问题
- MCP：通常不会直接暴露；若必须映射，用 `validation_failed`

### adapterNotVerified

- 含义：适配器尚未验证通过
- 场景：导入后未跑验证、重验证前设备被拦截
- UI：引导进入验证向导
- MCP：`adapter_not_verified`

### adapterConflict

- 含义：适配器与当前设备不匹配
- 场景：粗筛通过但精匹配失败
- UI：提示切换模板或高级模式
- MCP：`validation_failed`

### adapterVerificationFailed

- 含义：验证流程失败
- 场景：用户反馈“反应不对”、验证步骤超时、`stop_all` 验证失败
- UI：允许重试验证
- MCP：`adapter_verification_failed`

### adapterRevoked

- 含义：适配器曾通过验证，但现在被撤销或需要重验证
- 场景：版本变化、GATT 指纹变化、安全策略收紧
- UI：提示重新验证
- MCP：`adapter_revoked`

### mcpServer

- 含义：MCP 服务启动或运行异常
- UI：MCP 页显示错误态
- MCP：`mcp_internal_error`

### storage

- 含义：本地存储读写失败
- UI：轻量提示或错误页
- MCP：`mcp_internal_error`

### securityLock

- 含义：当前操作被本地安全锁拦截
- UI：显示解锁流程
- MCP：`validation_failed`

### unknown

- 含义：未归类异常
- UI：通用错误态
- MCP：`mcp_internal_error`

## 6. UI 表现规则

- 可恢复错误：提示 + 下一步建议
- 阻断错误：页面级错误态或弹窗
- 安全错误：必须明确，不弱化
- 技术细节：不直接展示原始异常

## 7. MCP 映射规则

MCP 错误必须结构化返回：

- `ok`
- `error.code`
- `error.message`
- `error.recoverable`
- `error.details`

适配器相关新增稳定错误码：

- `adapter_not_verified`
- `adapter_verification_failed`
- `adapter_revoked`

## 8. 日志规则

日志中允许记录：

- `Failure.code`
- 来源模块
- 操作上下文
- 简短调试信息

日志中禁止记录：

- 完整 BLE payload
- 敏感控制历史
- 隐私聊天原文

## 9. 测试要求

至少覆盖：

- 适配器导入校验失败映射
- 未验证适配器被 MCP 拒绝
- `stop_all` 失败和抢占相关错误
- EMS 超限错误映射
- UI 是否针对关键 Failure 渲染正确状态
