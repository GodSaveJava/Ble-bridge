# Adapter SDK 与验证流程规范（MVP）

## 1. 文档目的

本规范定义 ToyLink AI 的“设备适配器接入模式”，目标是：

- 不要求官方逐个逆向所有玩具
- 允许用户/社区提供适配器
- 保证所有控制命令都经过统一安全闸门
- 保持 Clean Architecture 与 `ToyDevice` 抽象不被破坏

## 2. 核心原则

1. 适配器可扩展，安全规则不可扩展  
2. 任何入口（UI/MCP/系统任务）都必须经过 `SafetyGuard`  
3. 适配器只能实现协议映射，不允许绕过应用层直接发高危命令  
4. 未验证通过的适配器不得进入 MCP 可调用列表  
5. 默认本地优先，不上传设备控制与原始 BLE 数据

## 3. 架构落点

### 3.1 目录建议

- `lib/domain/devices/toy_device.dart`
- `lib/domain/entities/adapter_manifest.dart`
- `lib/application/services/adapter_registry.dart`
- `lib/application/services/adapter_validator.dart`
- `lib/application/services/safety_guard.dart`
- `lib/infrastructure/adapters/`（具体设备适配器实现）
- `lib/infrastructure/storage/verified_adapter_store.dart`

### 3.2 角色边界

- `AdapterManifest`：描述能力与约束，不执行 BLE。
- `ToyDevice` 实现类：把标准控制语义映射为具体协议。
- `AdapterRegistry`：管理可用适配器与活跃适配器。
- `AdapterValidator`：导入后执行低风险验证流程。
- `SafetyGuard`：统一安全判断与拦截（全局强制）。

## 4. AdapterManifest（JSON）规范

> 本节是接入“脚手架模式”的关键合同，字段稳定后尽量不破坏性变更。

```json
{
  "adapterId": "sosexy.v1",
  "displayName": "SOSEXY Adapter",
  "protocolKey": "sosexy",
  "version": "1.0.0",
  "bleNamePrefixes": ["SOSEXY"],
  "gatt": {
    "serviceUuid": "0000fff0-0000-1000-8000-00805f9b34fb",
    "writeCharacteristicUuid": "0000fff3-0000-1000-8000-00805f9b34fb",
    "notifyCharacteristicUuid": "0000fff4-0000-1000-8000-00805f9b34fb",
    "writeWithoutResponse": true
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
  "safety": {
    "emsSoftLimit": 8,
    "emsHardLimit": 20,
    "requireConfirmationAboveSoftLimit": true
  },
  "status": "unverified"
}
```

## 5. 用户执行流（导入到可用）

1. 用户在“设备管理”导入适配器 JSON。  
2. 系统做静态校验（字段完整性、范围合法性、版本兼容）。  
3. 用户连接目标设备。  
4. 进入“低强度验证向导”：  
   - `set_suck(10, mode=1)`  
   - `set_vibe(10, mode=1)`  
   - `set_ems(1, mode=1)`  
   - `stop_all()`  
5. 4 项全部通过后，将适配器标记 `verified`。  
6. 仅 `verified` 适配器允许被 MCP 工具路由。

## 6. 系统响应流（统一安全路径）

1. 页面或 MCP 发起 `ControlCommand`。  
2. 应用层先调用 `SafetyGuard.evaluate(command, policy)`。  
3. 安全检查结果分三类：
   - `allowed`：直接执行  
   - `confirmationRequired`：等待用户确认  
   - `rejected`：返回结构化 `Failure`  
4. 允许执行后，路由到 `ActiveDeviceRegistry` 当前活跃 `ToyDevice`。  
5. `ToyDevice` 协议编码后写入 BLE（串行队列）。  
6. 状态回流到 Riverpod provider 与 MCP 响应。

## 7. SafetyGuard 强制规则（MVP）

1. EMS 强度 `0..8`：允许  
2. EMS 强度 `9..20`：需要明确确认  
3. EMS 强度 `>20`：拒绝  
4. `stop_all` 为最高优先级，必须抢占普通命令  
5. 未连接活跃设备时拒绝控制命令，返回 `Failure.noActiveDevice`  
6. 锁屏状态下拒绝敏感操作，返回 `Failure.securityLock`

## 8. MCP 接入边界

1. MCP 不直接调用 BLE 层。  
2. MCP 只调用 Application UseCase。  
3. MCP 与 UI 共享同一 `SafetyGuard`。  
4. 未验证适配器或未连接设备时，MCP 返回结构化错误。  
5. MCP 日志脱敏，不记录完整原始 payload。

## 9. 失败处理与用户提示

统一对接 `docs/07-failure-catalog.md`：

- `validation`
- `noActiveDevice`
- `deviceWrite`
- `securityLock`
- `mcpServer`
- `unknown`

所有错误都要可追踪（日志）且可理解（中文提示）。

## 10. 验收标准（本规范落地后）

1. 能导入 manifest 并完成静态校验。  
2. 能跑完低强度验证向导。  
3. 仅 `verified` 适配器可进入 MCP 调用。  
4. 所有命令均经过 `SafetyGuard`。  
5. `stop_all` 在队列中可抢占生效。  
6. 文档与代码边界保持一致（不跨层直调）。

## 11. 与现有文档的关系

- `docs/02-domain-interfaces-and-state-machines.md`：状态机基线  
- `docs/03-mcp-tool-contract.md`：工具合同  
- `docs/06-implementation-roadmap.md`：实施顺序  
- `docs/07-failure-catalog.md`：错误统一表达  
- `docs/09-testing-strategy.md`：测试优先级与 Fake 策略  
- `docs/10-routing-and-provider-map.md`：页面与 provider 映射  

## 12. 版本与变更策略

- 本文档版本：`v1.0`  
- 若修改安全规则或 manifest 必填字段，必须新增 ADR 并更新测试用例。  
