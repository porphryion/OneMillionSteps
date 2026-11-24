import Flutter
import HealthKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let healthSteps = HealthSteps()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HealthSteps") {
      healthSteps.register(with: registrar.messenger())
    }
  }
}

/// Reads the step count from Apple Health for lib/steps/health_step_source.dart.
///
/// Steps are summed per local day with a statistics query, so an iPhone and
/// an Apple Watch are not counted twice. Steps typed in by hand in the Health
/// app are left out.
final class HealthSteps {
  private let store = HKHealthStore()
  private let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount)!
  private var channel: FlutterMethodChannel?

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "onemillionsteps/health_steps", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.method {
      case "authorize":
        self.authorize(result)
      case "dailySteps":
        let args = call.arguments as? [String: Any]
        guard let since = (args?["since"] as? NSNumber)?.doubleValue else {
          result(FlutterError(code: "bad_arguments", message: "since is missing", details: nil))
          return
        }
        self.dailySteps(since: Date(timeIntervalSince1970: since / 1000), result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  /// Asks for read access once. iOS never says whether it was granted.
  private func authorize(_ result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(false)
      return
    }
    store.requestAuthorization(toShare: [], read: [stepCount]) { success, _ in
      DispatchQueue.main.async { result(success) }
    }
  }

  /// Steps per local day from [since] on, as [{"start": ms, "steps": n}].
  /// "start" is the day's midnight; the first day counts only from [since].
  private func dailySteps(since: Date, _ result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result([])
      return
    }
    let anchor = Calendar.current.startOfDay(for: since)
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      HKQuery.predicateForSamples(withStart: since, end: nil, options: .strictStartDate),
      // Samples without the key are kept; only hand-typed ones are left out.
      NSPredicate(format: "metadata.%K != YES", HKMetadataKeyWasUserEntered),
    ])
    let query = HKStatisticsCollectionQuery(
      quantityType: stepCount,
      quantitySamplePredicate: predicate,
      options: .cumulativeSum,
      anchorDate: anchor,
      intervalComponents: DateComponents(day: 1))
    query.initialResultsHandler = { _, collection, error in
      guard let collection else {
        let message = error?.localizedDescription ?? "no results"
        DispatchQueue.main.async {
          result(FlutterError(code: "query_failed", message: message, details: nil))
        }
        return
      }
      var days: [[String: Any]] = []
      collection.enumerateStatistics(from: anchor, to: Date()) { statistics, _ in
        guard let sum = statistics.sumQuantity() else { return }
        days.append([
          "start": Int64(statistics.startDate.timeIntervalSince1970 * 1000),
          "steps": Int(sum.doubleValue(for: .count()).rounded()),
        ])
      }
      DispatchQueue.main.async { result(days) }
    }
    store.execute(query)
  }
}
