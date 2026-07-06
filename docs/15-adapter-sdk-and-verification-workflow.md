# 适配器系统与验证流程规范（MVP）

## 1. 文档目的

本文件定义 ToyLink AI 第一阶段的设备扩展方案。

ToyLink AI 不以“官方逐个逆向所有玩具”为目标，而是提供一套安全、可扩展、可分享的适配器系统，让用户在 App 内完成：

- 连接玩具
- 选择或导入适配器
- 运行低风险验证向导
- 启用已验证设备
- 通过本地 MCP 让外部 AI 控制玩具

本文件是后续实现 `AdapterManifest`、`AdapterRegistry`、`AdapterValidator`、模板向导和验证存储的唯一设计依据。

## 2. 第一阶段产品定位

ToyLink AI 第一阶段的角色是：

- 本地蓝牙连接与控制运行时
- 本地 MCP 控制桥
- 适配器导入、验证、启用平台

ToyLink AI 第一阶段不是：

- 官方逆向所有玩具的协议仓库
- 开放执行第三方代码插件的平台
- 以内置聊天为主入口的 AI 对话产品

### 2.1 目标闭环

第一阶段必须跑通以下闭环：

1. 用户在 App 内扫描并连接设备
2. 用户选择内置模板或导入适配器文件
3. 系统静态校验适配器
4. 用户完成低强度验证向导
5. 系统将设备与适配器标记为可用
6. 外部 AI 通过本地 MCP 控制设备

## 3. 核心原则

1. 适配器可以扩展，安全规则不能被第三方放宽
2. 任何控制入口都必须经过 `SafetyGuard`
3. 适配器负责协议映射，不负责越权控制
4. 未验证的适配器不得进入 MCP 控制链
5. 适配器文件允许分享，但验证结果不允许分享复用
6. 本地优先，不上传 BLE 原始数据和敏感控制记录

## 4. 适配器类型与执行模型

第一阶段只支持一种适配器模式：

- `说明书文件 + App 内置翻译器`

这意味着：

- 用户导入的是一个 `JSON` 说明书文件
- 文件只描述设备匹配条件、能力边界、范围、连接参数和 `codecKey`
- 真正的命令编码逻辑由 App 内置的少量翻译器负责

第一阶段不支持：

- 导入可执行代码型适配器
- 导入脚本
- 导入自定义动态库
- 由适配器文件直接声明原始字节命令模板并绕过内置 codec

### 4.1 为什么这样设计

这样做的原因是：

- 对普通用户更安全
- 对初期产品更可控
- 对架构更稳定
- 能支持“模板 + 分享 + 本机验证”的闭环

## 5. AdapterManifest 规范

`AdapterManifest` 是适配器说明书文件的领域模型。

### 5.1 必填字段

```json
{
  "schemaVersion": 1,
  "adapterId": "generic.triple_channel.v1",
  "displayName": "通用三通道模板",
  "protocolKey": "generic_triple_channel",
  "version": "1.0.0",
  "minAppVersion": "1.0.0",
  "adapterKind": "codecBacked",
  "codecKey": "generic_triple_channel_v1",
  "bleNamePrefixes": ["SOSEXY"],
  "matching": {
    "serviceUuids": ["0000fff0-0000-1000-8000-00805f9b34fb"],
    "manufacturerDataPattern": null,
    "priority": 100
  },
  "gatt": {
    "serviceUuid": "0000fff0-0000-1000-8000-00805f9b34fb",
    "writeCharacteristicUuid": "0000fff3-0000-1000-8000-00805f9b34fb",
    "notifyCharacteristicUuid": "0000fff4-0000-1000-8000-00805f9b34fb",
    "writeWithoutResponse": true
  },
  "connection": {
    "requiresBonding": false,
    "requestMtu": 185,
    "notifyRequired": false
  },
  "capabilities": {
    "supportsSuck": true,
    "supportsVibe": true,
    "supportsEms": true,
    "supportsSetAll": true,
    "supportsStopAll": true
  },
  "ranges": {
    "suckIntensity": {"min": 0, "max": 100},
    "vibeIntensity": {"min": 0, "max": 100},
    "emsIntensity": {"min": 0, "max": 20},
    "mode": {"min": 1, "max": 4}
  },
  "notes": "内置模板示例"
}
```

### 5.2 字段说明

- `schemaVersion`：适配器文件格式版本
- `adapterId`：稳定的适配器标识
- `displayName`：给用户看的名称
- `protocolKey`：协议模板类型
- `version`：适配器版本
- `minAppVersion`：最小兼容 App 版本
- `adapterKind`：第一阶段固定为 `codecBacked`
- `codecKey`：App 内置翻译器标识
- `bleNamePrefixes`：扫描粗筛用的设备名前缀
- `matching`：连接后精匹配规则
- `gatt`：连接与写入所需的 GATT 信息
- `connection`：连接提示与连接要求
- `capabilities`：设备支持的功能
- `ranges`：协议允许的参数范围
- `notes`：说明信息

### 5.3 明确不放进 manifest 的内容

以下内容不允许放进 `AdapterManifest`：

- `verified`
- `unverified`
- `verificationStatus`
- 用户验证记录
- 本机设备指纹
- 本机确认结果
- 本机撤销状态

原因：

- 这些都是本地运行时事实，不是适配器作者声明的事实

## 6. 本地验证记录模型

验证状态必须独立存储，不得写回分享文件。

### 6.1 推荐本地字段

- `manifestHash`
- `adapterId`
- `adapterVersion`
- `verificationStatus`
- `verifiedAt`
- `verifiedByAppVersion`
- `verifiedAgainst.deviceFingerprint`
- `verifiedAgainst.gattFingerprint`
- `verifiedAgainst.firmwareRevision`
- `verifiedSteps`
- `revokedReason`

### 6.2 verificationStatus 取值

- `unverified`
- `verified`
- `failed`
- `revoked`
- `needsReverify`

## 7. 适配器匹配与绑定算法

设备匹配必须分两阶段完成。

### 7.1 第一阶段：扫描粗筛

扫描时允许使用：

- `bleNamePrefixes`

作用：

- 只用于候选设备列表筛选
- 不能作为最终适配器绑定依据

### 7.2 第二阶段：连接后精匹配

连接后必须至少检查以下一项：

- `serviceUuid`
- `writeCharacteristicUuid`
- `notifyCharacteristicUuid`
- `manufacturerDataPattern`
- `gattFingerprint`

作用：

- 确认当前设备是否真的适合该适配器
- 防止多个品牌或型号共用名称前缀时误匹配

### 7.3 匹配失败处理

若粗筛通过但精匹配失败：

- 不得启用该适配器
- 返回 `adapterConflict` 或 `protocolUnsupported`
- 引导用户切换模板或进入高级模式

## 8. 有效安全策略合成规则

`SafetyGuard` 的最终规则不是只看一处，而是由三层共同决定。

固定公式：

`effectivePolicy = 全局安全上限 ∩ 设备能力上限 ∩ 适配器声明上限`

解释：

- 系统全局安全上限是最高优先级
- 设备能力上限来自 `ToyDevice` 或内置 codec
- 适配器声明上限只能收紧，不能放宽

### 8.1 第一阶段硬规则

- EMS `0..8`：允许
- EMS `9..20`：UI 可确认，MCP 直接拒绝
- EMS `>20`：拒绝
- `stop_all`：最高优先级
- 未验证适配器：拒绝控制
- 未连接活跃设备：拒绝控制

## 9. 用户执行流

### 9.1 普通用户主流程

1. 打开 App
2. 扫描并连接设备
3. 选择系统推荐模板或导入适配器文件
4. 系统做静态校验
5. 进入低强度验证向导
6. 用户确认每一步体感是否正确
7. 全部通过后启用设备
8. 打开 MCP，供外部 AI 控制

### 9.2 导入分享文件

适配器文件允许导出分享。

但导入分享文件后必须：

- 重新静态校验
- 重新精匹配设备
- 重新运行验证向导

不允许：

- 直接继承别人机器上的 `verified` 状态

## 10. 适配器验证向导

### 10.1 第一阶段默认验证步骤

按设备能力裁剪后执行：

- `set_suck(10, mode=1)`
- `set_vibe(10, mode=1)`
- `set_ems(1, mode=1)`
- `stop_all()`

### 10.2 通过标准

某一步“通过”必须同时满足：

- 命令成功进入执行链路
- 未发生连接中断或写入失败
- 用户明确确认“反应正确”

如果设备支持状态回流或 notify：

- 还应记录状态回流是否正常

### 10.3 能力裁剪规则

如果设备不支持某通道：

- 该步骤跳过
- 但必须记录为 `skipped`

`stop_all` 不允许跳过，必须验证。

### 10.4 超时与失败规则

- 单步验证超时：记为失败
- 单步可允许一次重试
- 任一步失败后，本轮状态为 `failed`
- 用户可重新运行整个验证流程

## 11. 命令队列与 stop_all 抢占合同

这是安全关键路径，必须明确。

### 11.1 stop_all 的队列行为

- `stop_all` 必须插入队头
- 队列中尚未发送的普通命令全部丢弃
- 已经发出的 in-flight 命令允许完成
- `stop_all` 成功后，旧的普通命令不得继续落地

### 11.2 set_all 的默认语义

`set_all` 是一个逻辑请求，不代表设备一定有原生命令。

如果设备无原生组合命令：

- application 层允许拆成有序序列
- 若序列中途失败，应返回失败并附最新已知状态

第一阶段默认不承诺事务回滚。

## 12. MCP 接入边界

ToyLink AI 第一阶段只开放本地 `MCP` 控制入口。

固定链路：

`McpToolRouter -> SafetyGuard -> Application UseCase -> ActiveDeviceRegistry -> ToyDevice`

### 12.1 MCP 对未验证设备的行为

- 返回结构化错误
- 不执行命令
- 不触发交互确认

### 12.2 MCP 对 EMS 超软上限的行为

- 不进入确认流
- 直接返回固定错误码

### 12.3 MCP 不允许做的事

- 直接操作 BLE
- 绕过适配器验证状态
- 绕过 `SafetyGuard`

## 13. 适配器错误码与 Failure 映射

第一阶段应补充以下适配器错误：

- `adapterSchemaInvalid`
- `adapterNotVerified`
- `adapterConflict`
- `adapterVerificationFailed`
- `adapterRevoked`

推荐 MCP 错误码映射：

- `adapterSchemaInvalid` -> `validation_failed`
- `adapterNotVerified` -> `adapter_not_verified`
- `adapterConflict` -> `validation_failed`
- `adapterVerificationFailed` -> `adapter_verification_failed`
- `adapterRevoked` -> `adapter_revoked`

## 14. 第一阶段模板体系

第一阶段建议内置以下模板：

- `generic_single_channel_v1`
- `generic_dual_channel_v1`
- `generic_triple_channel_v1`
- `sosexy_v1`
- `custom_uuid_probe_v1`

### 14.1 普通用户填写内容

普通模式只允许用户填写：

- 适配器名称
- 设备名称关键字
- 选择模板
- 勾选支持的功能

### 14.2 高级模式填写内容

高级模式允许额外填写：

- `serviceUuid`
- `writeCharacteristicUuid`
- `notifyCharacteristicUuid`
- `writeWithoutResponse`
- 范围参数
- 匹配规则

### 14.3 用户不允许填写的内容

- 原始 BLE 字节命令
- 系统安全上限
- MCP 工具定义
- 队列抢占逻辑

## 15. 存储与分享规则

### 15.1 可分享内容

允许分享：

- `AdapterManifest` 文件

### 15.2 不可分享内容

不允许分享：

- 本机验证结果
- 本机设备指纹
- 本机失败记录
- 本机锁定与撤销记录

### 15.3 触发重验证的条件

以下任意一项变化，都应转为 `needsReverify`：

- `adapterVersion`
- `schemaVersion`
- `gattFingerprint`
- 设备固件版本
- App 安全策略收紧

## 16. 验收标准

本规范可认为完成，需满足：

1. 适配器文件格式稳定
2. 验证状态与 manifest 分离
3. 模板、导入、验证、启用链路清楚
4. 未验证适配器无法进入 MCP
5. `stop_all` 抢占合同明确
6. UI 和 MCP 的安全行为差异明确
7. 与 `CODEX.md`、`docs/03`、`docs/07` 保持一致
