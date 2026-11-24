import 'package:flutter/foundation.dart';

/// Test buttons on the race tab (add steps, skip to the next day).
///
/// On in debug builds. Release builds turn them on with
/// `--dart-define=TEST_TOOLS=true`. They only show with the fake step source,
/// because they add fake steps and move the game clock.
const bool kTestTools = kDebugMode || bool.fromEnvironment('TEST_TOOLS');

/// Forces the fake step source on iOS too: `--dart-define=FAKE_STEPS=true`.
const bool kFakeSteps = bool.fromEnvironment('FAKE_STEPS');

/// Whether steps come from Apple Health. Only on iOS for now; Android and
/// desktop keep the fake source until Health Connect is wired up.
bool get useHealthSteps =>
    !kFakeSteps && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
