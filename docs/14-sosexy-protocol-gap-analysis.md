# SOSEXY 协议差异分析（Gap Analysis v1）

## 1. 文档目的

本文件用于对比“抓包核对结果”与“当前代码实现”，输出可执行修改清单。

- 对比来源：
  - `/docs/13-sosexy-verified-protocol-table-v1.md`
  - 当前实现文件：
    - `/lib/infrastructure/devices/sosexy/sosexy_gatt_profile.dart`
    - `/lib/infrastructure/devices/sosexy/sosexy_protocol_spec.dart`
    - `/lib/infrastructure/devices/sosexy/sosexy_protocol_codec.dart`

## 2. 必须修改（Blocking）

> 满足任一项即进入必须修改：  
> 1) 抓包 `verified` 与当前实现不一致；  
> 2) 会导致命令不可用或行为错误；  
> 3) 会造成安全风险（尤其是 stop/ems 行为）。

| 序号 | 差异项 | 抓包结论 | 当前实现 | 影响 | 修改建议 |
|---|---|---|---|---|---|
| 1 | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 |

## 3. 建议修改（Recommended）

> 不改也可运行，但会影响可维护性、可观测性或未来扩展。

| 序号 | 差异项 | 抓包结论 | 当前实现 | 影响 | 修改建议 |
|---|---|---|---|---|---|
| 1 | 待填写 | 待填写 | 待填写 | 待填写 | 待填写 |

## 4. 暂不修改（Accepted For Now）

> 当前版本可接受，记录原因，后续在 ADR 或协议升级时再处理。

| 序号 | 项目 | 当前状态 | 暂缓原因 | 复审触发条件 |
|---|---|---|---|---|
| 1 | 待填写 | 待填写 | 待填写 | 待填写 |

## 5. stop_all 专项核对

必须单独回答：

1. `stop_all` 是否独立命令？
2. 是否依赖“所有通道置零”组合语义？
3. stop 是否具有最高优先级（需要清空普通队列）？

填写模板：

- 结论：
- 证据（抓包片段/时间点）：
- 对当前 `stopAll()` 实现影响：

## 6. 本轮修改入口建议

若产生“必须修改”，默认按以下顺序改动：

1. `sosexy_gatt_profile.dart`（UUID / 写入类型）
2. `sosexy_protocol_spec.dart`（帧常量与结构定义）
3. `sosexy_protocol_codec.dart`（编码逻辑）
4. `sosexy_device.dart`（命令调用方式与 stop 优先级）
5. 对应单元测试（codec + safety + router）

## 7. 完成判定

本文件可标记“已完成”需满足：

- “必须修改”项全部关闭并有 commit 记录；
- 最小真机回归四项通过；
- `docs/13` 关键字段状态已同步更新；
- 对应测试（至少 codec + stop 行为）通过。
