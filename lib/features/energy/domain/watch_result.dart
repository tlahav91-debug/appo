enum WatchResultStatus { success, insufficientEnergy, alreadyUnlocked, error }

class WatchResult {
  final WatchResultStatus status;
  final int? energyRemaining;
  final int? currentEnergy;
  final int? requiredEnergy;
  final String? errorMessage;

  const WatchResult._({
    required this.status,
    this.energyRemaining,
    this.currentEnergy,
    this.requiredEnergy,
    this.errorMessage,
  });

  factory WatchResult.success(int energyRemaining) => WatchResult._(
        status: WatchResultStatus.success,
        energyRemaining: energyRemaining,
      );

  factory WatchResult.alreadyUnlocked() => const WatchResult._(
        status: WatchResultStatus.alreadyUnlocked,
      );

  factory WatchResult.insufficientEnergy({required int current, required int required}) =>
      WatchResult._(
        status: WatchResultStatus.insufficientEnergy,
        currentEnergy: current,
        requiredEnergy: required,
      );

  factory WatchResult.error(String message) => WatchResult._(
        status: WatchResultStatus.error,
        errorMessage: message,
      );

  bool get isSuccess =>
      status == WatchResultStatus.success || status == WatchResultStatus.alreadyUnlocked;
}
