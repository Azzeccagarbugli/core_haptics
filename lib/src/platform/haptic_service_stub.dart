import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/services.dart' show HapticFeedback;

import '../api/errors.dart';

/// Abstract interface for platform-specific haptic feedback implementations.
abstract class HapticServiceBase {
  /// Whether the device supports haptic feedback.
  Future<bool> get isSupported;

  /// Whether the platform supports advanced Core Haptics features.
  ///
  /// Returns `true` on iOS/macOS, `false` elsewhere.
  bool get supportsAdvancedHaptics;

  /// Trigger a light impact haptic feedback.
  Future<void> lightImpact();

  /// Trigger a medium impact haptic feedback.
  Future<void> mediumImpact();

  /// Trigger a heavy impact haptic feedback.
  Future<void> heavyImpact();

  /// Trigger a soft impact haptic feedback.
  Future<void> softImpact();

  /// Trigger a rigid impact haptic feedback.
  Future<void> rigidImpact();

  /// Trigger a success notification haptic feedback.
  Future<void> success();

  /// Trigger a warning notification haptic feedback.
  Future<void> warning();

  /// Trigger an error notification haptic feedback.
  Future<void> error();

  /// Trigger a selection change haptic feedback.
  Future<void> selection();
}

/// Flutter fallback implementation using HapticFeedback service.
///
/// Provides basic haptic feedback on Android and other platforms
/// that support Flutter's built-in haptic APIs.
class FlutterHapticService implements HapticServiceBase {
  @override
  bool get supportsAdvancedHaptics => false;

  @override
  Future<bool> get isSupported async {
    // Flutter's HapticFeedback is available on Android and iOS.
    // On web it uses the Vibration API if available.
    // We return true as Flutter handles unsupported cases gracefully.
    return !kIsWeb || _webSupportsVibration;
  }

  // Web vibration support check (simplified - Flutter handles this internally)
  bool get _webSupportsVibration => kIsWeb;

  @override
  Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  @override
  Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  @override
  Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  @override
  Future<void> softImpact() async {
    // No direct equivalent - use light impact as closest match
    await HapticFeedback.lightImpact();
  }

  @override
  Future<void> rigidImpact() async {
    // No direct equivalent - use heavy impact as closest match
    await HapticFeedback.heavyImpact();
  }

  @override
  Future<void> success() async {
    // No direct equivalent - use medium impact for positive feedback
    await HapticFeedback.mediumImpact();
  }

  @override
  Future<void> warning() async {
    // No direct equivalent - use heavy impact for warning
    await HapticFeedback.heavyImpact();
  }

  @override
  Future<void> error() async {
    // Use vibrate for error - more noticeable
    await HapticFeedback.vibrate();
  }

  @override
  Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }
}

/// Factory for creating the appropriate haptic service based on platform.
///
/// On web/WASM, always returns [FlutterHapticService] since native
/// Core Haptics is not available.
class HapticServiceFactory {
  HapticServiceFactory._();

  static HapticServiceBase? _testService;

  /// Returns `true` if running on iOS or macOS (platforms with Core Haptics).
  ///
  /// On web/WASM, always returns `false`.
  static bool get isApplePlatform => false;

  /// Create the appropriate haptic service for the current platform.
  ///
  /// On web/WASM, always returns [FlutterHapticService].
  static HapticServiceBase create({Object? bindings}) {
    if (_testService != null) return _testService!;
    return FlutterHapticService();
  }

  /// Inject a test service for unit testing.
  @visibleForTesting
  static void setTestService(HapticServiceBase? service) {
    _testService = service;
  }

  /// Reset the factory for testing.
  @visibleForTesting
  static void reset() {
    _testService = null;
  }
}

/// Throws [HapticsException] if advanced haptics are not supported.
///
/// On web/WASM, always throws since Core Haptics is not available.
void ensureAdvancedHapticsSupported() {
  // Check test service first (allows mocking platform behavior in tests)
  final testService = HapticServiceFactory._testService;
  if (testService != null) {
    if (!testService.supportsAdvancedHaptics) {
      throw HapticsException(
        HapticsErrorCode.notSupported,
        'Advanced haptic features (HapticEngine, patterns, players) '
        'are only available on iOS and macOS. '
        'Use static methods like HapticEngine.lightImpact() for cross-platform support.',
      );
    }
    return;
  }

  // On web/WASM, advanced haptics are never supported
  throw HapticsException(
    HapticsErrorCode.notSupported,
    'Advanced haptic features (HapticEngine, patterns, players) '
    'are only available on iOS and macOS. '
    'Use static methods like HapticEngine.lightImpact() for cross-platform support.',
  );
}
