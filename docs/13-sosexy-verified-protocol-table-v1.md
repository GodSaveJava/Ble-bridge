# SOSEXY Verified Protocol Table v1

> 说明：本表用于沉淀“证据驱动”的协议结论。  
> `status` 仅允许：`verified` / `inferred` / `unknown`。

## A. GATT 识别信息

| 字段 | 当前值 | status | 证据来源（抓包时间点/截图/备注） |
|---|---|---|---|
| Service UUID | `0000fff0-0000-1000-8000-00805f9b34fb` | inferred | 当前实现默认值 |
| Write Characteristic UUID | `0000fff3-0000-1000-8000-00805f9b34fb` | inferred | 当前实现默认值 |
| Notify Characteristic UUID | `0000fff4-0000-1000-8000-00805f9b34fb` | inferred | 当前实现默认值 |
| Write Type | `without response` | inferred | 当前实现默认值 |

## B. 通道映射

| 业务通道 | 字节值 | status | 证据来源 |
|---|---:|---|---|
| suck | `0x01` | inferred | `SosexyProtocolSpec` |
| vibe | `0x03` | inferred | `SosexyProtocolSpec` |
| ems | `0x07` | inferred | `SosexyProtocolSpec` |

## C. 帧结构

当前实现假设帧结构：`[header0, header1, channel, mode, intensity, tail]`

| 字段 | 当前值 | status | 证据来源 |
|---|---|---|---|
| header0 | `0x55` | inferred | `SosexyProtocolSpec` |
| header1 | `0xAA` | inferred | `SosexyProtocolSpec` |
| channel index | `2` | inferred | `SosexyProtocolCodec` |
| mode index | `3` | inferred | `SosexyProtocolCodec` |
| intensity index | `4` | inferred | `SosexyProtocolCodec` |
| tail | `0xFF` | inferred | `SosexyProtocolSpec` |
| checksum | 无 | unknown | 待抓包确认 |

## D. stop_all 命令

| 字段 | 当前值 | status | 证据来源 |
|---|---|---|---|
| stop_all bytes | `[0x55,0xAA,0x00,0x00,0x00,0xFF]` | inferred | `SosexyProtocolCodec` |
| 是否独立命令 | unknown | unknown | 待抓包确认 |

## E. 范围与模式

| 参数 | 当前值 | status | 证据来源 |
|---|---|---|---|
| mode range | `1..4` | inferred | 当前实现 |
| suck intensity | `0..100` | inferred | 当前实现 |
| vibe intensity | `0..100` | inferred | 当前实现 |
| ems intensity | `0..20` | inferred | 当前实现 |

## F. 最小回归验证结果（核对后填写）

| 用例 | 预期 | 实际 | 结果 |
|---|---|---|---|
| `set_suck(10,1)` | 生效 |  |  |
| `set_vibe(10,1)` | 生效 |  |  |
| `set_ems(1,1)` | 生效 |  |  |
| `stop_all()` | 立即停止 |  |  |
