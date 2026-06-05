# SOSEXY Importable Adapter Config Spec

## Objective

把公开教程里整理出来的 SOSEXY 协议信息，收敛成一个可导入到 ToyLink AI 的 `AdapterManifest` 配置。

目标不是把所有逆向细节一次性“写死”，而是先提供一个：

- 用户可直接导入
- App 可识别为官方模板
- 可用于设备匹配、验证和后续控制接入

## Assumptions

1. 这份配置的主载体是现有的 `AdapterManifest` JSON，而不是新增一套独立配置格式。
2. 用户导入后，App 会把它当作官方模板处理，并接入现有的设备管理 / 验证 / 控制流程。
3. 公开教程已经足够支持第一版配置落地，但字节级命令细节后续仍可能需要 HCI 结果再校正。
4. 第一期优先收口 GATT、能力、范围、模板来源和导入体验，避免把协议结构做成难维护的散件。

## Config Shape

导入文件应当是标准 `AdapterManifest` JSON，并包含：

- `schemaVersion`
- `adapterId`
- `displayName`
- `protocolKey`
- `version`
- `minAppVersion`
- `adapterKind`
- `source`
- `codecKey`
- `bleNamePrefixes`
- `matching`
- `gatt`
- `connection`
- `capabilities`
- `ranges`
- `notes`

## Success Criteria

- 用户可以把这份 JSON 作为文件导入 App。
- 导入后，配置会被识别为 `official` 模板。
- App 会在设备管理页、扫描页和验证页里显示这份模板的正确来源与名称。
- 配置中的 GATT 信息与 SOSEXY 的教程版本保持一致。
- 配置文件可以被直接分享，不依赖额外脚本或手动拼字段。

## Open Question

- 字节级命令编码是否需要在下一轮再根据 HCI 结果精调。

