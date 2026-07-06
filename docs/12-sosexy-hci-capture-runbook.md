# SOSEXY 真实协议核对执行手册（HCI 抓包版）

## 1. 目标与完成标准

### 目标
在无官方协议文档前提下，通过 Android HCI 日志抓包，核对 SOSEXY 的真实 BLE 协议：

- Service UUID
- Write/Notify Characteristic UUID
- 写入类型（with response / without response）
- 命令帧结构（头、通道、模式、强度、尾/校验）
- `stop_all` 的真实命令模式

### 完成标准
以下条件全部满足，视为“第一步完成”：

1. `/docs/13-sosexy-verified-protocol-table-v1.md` 中关键字段均改为 `verified` 或保留明确证据不足说明。
2. `/docs/14-sosexy-protocol-gap-analysis.md` 形成“必须修改 / 建议修改 / 暂不修改”清单。
3. 最小真机回归 4 项通过：`set_suck`、`set_vibe`、`set_ems`、`stop_all`。

## 2. 安全边界（必须执行）

- EMS 仅允许低强度：`0..3`
- 单次动作持续时间：`<= 3 秒`
- 动作间隔：`>= 5 秒`
- 任何异常立即停止并断开连接
- 全流程禁止高风险强度验证

## 3. 采集准备

### 设备
- Android 真机（建议 Android 10+）
- SOSEXY 设备
- 官方/可用控制 App（用于触发真实动作）

### 手机设置
1. 打开开发者选项。
2. 开启 `Enable Bluetooth HCI snoop log`。
3. 重启蓝牙，确保后续日志完整。

## 4. 标准动作脚本（固定顺序）

执行时同步填写：`/docs/evidence/sosexy-action-log-v1.md`

1. 连接设备
2. `suck`：mode=1，intensity `10 -> 30`
3. `vibe`：mode=1，intensity `10 -> 30`
4. `ems`：mode=1，intensity `1 -> 3`
5. `stop_all`

每一步必须记录：

- 动作名
- 开始时间（精确到秒）
- 结束时间
- 体感是否符合预期
- 异常备注（延迟、断连、误触发）

## 5. 日志导出与提取

### 常见导出路径
- `/sdcard/btsnoop_hci.log`

### 推荐流程
1. 完成动作脚本后，关闭 HCI 开关（防止日志继续增长）。
2. 将 `btsnoop_hci.log` 拷贝到电脑。
3. 用 Wireshark 打开日志。
4. 定位目标设备连接会话，提取：
   - Service Discovery
   - Characteristic Discovery
   - Write Request / Write Command
   - Notification（若有）

## 6. 协议字段核对规则

将结论写入：

- `/docs/13-sosexy-verified-protocol-table-v1.md`
- `/docs/14-sosexy-protocol-gap-analysis.md`

### 必提字段
- Service UUID
- Write Characteristic UUID
- Notify Characteristic UUID（若存在）
- 写入类型（with / without response）
- 帧结构字段：header、channel、mode、intensity、tail/checksum

### 证据一致性要求
- 同一动作至少出现 2 次一致字节模式。
- 强度变化时，至少有 1 个字节呈稳定规律变化。
- 模式变化时，至少有 1 个字节呈稳定规律变化。

## 7. 最小真机回归验证（核对后执行）

基于更新后的协议实现执行：

1. `set_suck(10, mode=1)` 生效
2. `set_vibe(10, mode=1)` 生效
3. `set_ems(1, mode=1)` 生效
4. `stop_all()` 立即生效

以上全部通过后，才进入下一阶段编码扩展。

## 8. 阶段产出物

本阶段结束时，仓库应包含并填充：

- `/docs/evidence/sosexy-action-log-v1.md`
- `/docs/13-sosexy-verified-protocol-table-v1.md`
- `/docs/14-sosexy-protocol-gap-analysis.md`
