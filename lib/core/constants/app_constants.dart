class AppConstants {
  const AppConstants._();

  static const int emsSoftLimit = 8;
  static const int emsHardLimit = 20;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration commandTimeout = Duration(seconds: 5);
  static const Duration scanTimeout = Duration(seconds: 10);
}
