import '../../application/providers/application_providers.dart';

String hardwareRuntimeModeLabel(HardwareRuntimeMode mode) {
  return switch (mode) {
    HardwareRuntimeMode.mockBle => '硬件模式：Mock BLE',
    HardwareRuntimeMode.realBle => '硬件模式：Real BLE',
  };
}

String hardwareRuntimeModeDescription(HardwareRuntimeMode mode) {
  return switch (mode) {
    HardwareRuntimeMode.mockBle =>
      '当前使用本地模拟设备，只适合开发、演示和自动化测试。',
    HardwareRuntimeMode.realBle =>
      '当前会扫描并连接真实 BLE 硬件，适合真机验证和内测。',
  };
}
