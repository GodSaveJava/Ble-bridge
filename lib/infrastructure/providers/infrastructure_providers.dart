import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/hardware_repository.dart';
import '../mock/mock_hardware_repository.dart';

final defaultHardwareRepositoryProvider = Provider<HardwareRepository>((ref) {
  final MockHardwareRepository repository = MockHardwareRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
