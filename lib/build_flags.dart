import 'package:flutter/foundation.dart';

/// Test buttons on the race tab (add steps, skip to the next day).
///
/// On in debug builds. Release builds turn them on with
/// `--dart-define=TEST_TOOLS=true`, so a TestFlight build can be played
/// before real step data is wired up. Store builds leave it off.
const bool kTestTools = kDebugMode || bool.fromEnvironment('TEST_TOOLS');
