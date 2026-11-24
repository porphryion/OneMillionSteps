import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_million_steps/steps/health_step_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(HealthStepSource.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('turns HealthKit day buckets into totals per local day', () async {
    MethodCall? asked;
    messenger.setMockMethodCallHandler(channel, (call) async {
      asked = call;
      return [
        {'start': DateTime(2026, 11, 24).millisecondsSinceEpoch, 'steps': 4210},
        {'start': DateTime(2026, 11, 25).millisecondsSinceEpoch, 'steps': 12},
      ];
    });

    final since = DateTime(2026, 11, 24, 18, 30);
    final totals = await HealthStepSource().dailyTotalsSince(since);

    expect(asked!.method, 'dailySteps');
    expect(asked!.arguments, {'since': since.millisecondsSinceEpoch});
    expect(totals, {'2026-11-24': 4210, '2026-11-25': 12});
  });

  test('counts nothing new while Health cannot be read', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'query_failed', message: 'locked');
    });

    expect(await HealthStepSource().dailyTotalsSince(DateTime(2026)), isEmpty);
  });

  test('asking for access does not throw without Health', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'unavailable');
    });

    await HealthStepSource().authorize();
  });
}
