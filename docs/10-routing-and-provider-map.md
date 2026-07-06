# 路由与 Provider 映射

## 1. 文档目的

本文件把 ToyLink AI 第一阶段的产品设计翻译成 Flutter 落地结构。

当前产品主线是：

- 用户自行配对设备
- 用户选择或导入适配器
- 用户完成验证
- 外部 AI 通过 MCP 控制

所以路由与 provider 也必须围绕这条主线组织。

## 2. 路由设计总原则

- 路由只负责页面进入关系
- provider 负责状态来源
- 共享状态按能力建模
- 页面不持有系统真相状态
- 锁屏默认采用覆盖层

## 3. 第一阶段默认导航结构

### 根级页面

- `AppShell`
- `LockOverlayHost`

### 底部导航主区

- `HomePage`
- `ControlPage`
- `McpPage`
- `SettingsPage`

### 独立 push 页面

- `ScanPage`
- `AdapterSetupPage`
- `VerificationWizardPage`
- `DeviceManagerPage`

第一阶段不把 `ChatPage` 作为主导航页面。

## 4. 路由清单

- `/`
- `/home`
- `/control`
- `/mcp`
- `/settings`
- `/scan`
- `/adapter-setup`
- `/verification`
- `/device-manager`

## 5. Provider 组织方式

provider 按能力分层，而不是按页面复制。

### 环境与权限

- `bluetoothEnvironmentProvider`
- `permissionStatusProvider`

### 扫描与连接

- `scanControllerProvider`
- `scanResultsProvider`
- `connectionControllerProvider`

### 适配器系统

- `adapterTemplateProvider`
- `adapterImportControllerProvider`
- `adapterValidationControllerProvider`
- `verifiedAdapterProvider`

### 活跃设备与控制

- `activeDeviceProvider`
- `activeDeviceStatusProvider`
- `controlPanelControllerProvider`
- `safetyGuardProvider`

### MCP

- `mcpServiceProvider`
- `mcpStatusProvider`
- `mcpEndpointProvider`

### 安全与锁屏

- `appLockStateProvider`
- `unlockControllerProvider`

### 设置与偏好

- `settingsProvider`
- `scanPrefixProvider`
- `privacySettingsProvider`

## 6. 页面与 Provider 映射

### HomePage

依赖：

- `bluetoothEnvironmentProvider`
- `permissionStatusProvider`
- `activeDeviceProvider`
- `activeDeviceStatusProvider`
- `verifiedAdapterProvider`
- `mcpStatusProvider`
- `appLockStateProvider`

### ScanPage

依赖：

- `permissionStatusProvider`
- `scanControllerProvider`
- `scanResultsProvider`
- `connectionControllerProvider`

### AdapterSetupPage

依赖：

- `adapterTemplateProvider`
- `adapterImportControllerProvider`
- `activeDeviceProvider`

### VerificationWizardPage

依赖：

- `adapterValidationControllerProvider`
- `activeDeviceProvider`
- `activeDeviceStatusProvider`
- `safetyGuardProvider`

### ControlPage

依赖：

- `activeDeviceProvider`
- `activeDeviceStatusProvider`
- `verifiedAdapterProvider`
- `controlPanelControllerProvider`
- `safetyGuardProvider`
- `appLockStateProvider`

### McpPage

依赖：

- `mcpServiceProvider`
- `mcpStatusProvider`
- `mcpEndpointProvider`
- `activeDeviceProvider`
- `verifiedAdapterProvider`

### DeviceManagerPage

依赖：

- `adapterTemplateProvider`
- `verifiedAdapterProvider`
- `adapterImportControllerProvider`
- `appLockStateProvider`

### SettingsPage

依赖：

- `settingsProvider`
- `privacySettingsProvider`
- `scanPrefixProvider`
- `appLockStateProvider`

## 7. 页面级 controller 规则

- 共享业务状态优先放能力型 provider
- 页面只是组合多个能力时，不新建重型 page provider
- 只有明显独立流程的页面，才加 page-level controller

推荐需要 page controller 的页面：

- `HomePage`
- `VerificationWizardPage`
- `DeviceManagerPage`

## 8. 锁屏覆盖层接入规则

- App Lock 不默认通过独立 route 实现
- 锁层作为页面覆盖层注入宿主
- 被覆盖页面状态继续存在
- 解锁成功后恢复当前上下文
- 锁层不替代 `SafetyGuard`

## 9. 路由与 Failure 的关系

- `permissionDenied`：扫描页显示权限引导
- `noActiveDevice`：控制页显示空状态并引导去 `/scan`
- `adapterNotVerified`：控制页与 MCP 页提示先验证
- `securityLock`：当前页挂起并展示锁层
- `mcpServer`：MCP 页展示错误态，不强制跳转

## 10. 第一阶段实现建议

如果开始编码，优先先落：

1. `/home`
2. `/scan`
3. `/adapter-setup`
4. `/verification`
5. `/control`
6. `/mcp`
7. `/settings`

这样可以最早把“配对 -> 验证 -> MCP”主链路接起来。
