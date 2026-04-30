class SafetyPolicy {
  const SafetyPolicy({
    this.emsSoftLimit = 8,
    this.emsHardLimit = 20,
    this.requiresExplicitConfirmationAboveSoftLimit = true,
  });

  final int emsSoftLimit;
  final int emsHardLimit;
  final bool requiresExplicitConfirmationAboveSoftLimit;
}
