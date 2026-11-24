import 'package:flutter/services.dart';

import '../game/economy.dart';
import 'step_source.dart';

/// Real steps from Apple Health on iOS.
///
/// The native side lives in `ios/Runner/AppDelegate.swift` (HealthSteps).
/// It sums the step count per local day with HealthKit, so steps from an
/// iPhone and an Apple Watch are not counted twice, and leaves out steps that
/// were typed in by hand in the Health app.
class HealthStepSource implements StepSource {
  HealthStepSource({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'onemillionsteps/health_steps';

  final MethodChannel _channel;

  /// Asks for read access to the step count. iOS shows its sheet only the
  /// first time, and never says whether access was granted: without access,
  /// Health just returns no steps.
  Future<void> authorize() async {
    try {
      await _channel.invokeMethod<bool>('authorize');
    } on PlatformException {
      // No Health on this device (an iPad, for example). No steps will come.
    } on MissingPluginException {
      // Not running on iOS.
    }
  }

  @override
  Future<Map<String, int>> dailyTotalsSince(DateTime since) async {
    try {
      final days = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'dailySteps',
        {'since': since.millisecondsSinceEpoch},
      );
      final totals = <String, int>{};
      for (final day in days ?? const <Map<Object?, Object?>>[]) {
        final start = (day['start']! as num).toInt();
        totals[dayKey(DateTime.fromMillisecondsSinceEpoch(start))] =
            (day['steps']! as num).toInt();
      }
      return totals;
    } on PlatformException {
      // Health data cannot be read while the phone is locked. Nothing new is
      // counted now; the next sync picks the steps up.
      return const {};
    } on MissingPluginException {
      return const {};
    }
  }
}
