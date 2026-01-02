import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

import '../platform/haptic_service.dart';
import 'errors.dart';
import 'types.dart';

/// Callback for engine lifecycle events and interruptions.
typedef HapticEngineEventHandler = void Function(
  HapticEngineEvent event,
  String? message,
);

/// Manages the Core Haptics engine lifecycle and pattern loading.
///
/// For simple one-liner haptics, use the static methods:
/// ```dart
/// await HapticEngine.success();
/// await HapticEngine.mediumImpact();
/// ```
///
/// For advanced control (looping, dynamic parameters, engine events),
/// create an engine instance:
/// ```dart
/// final engine = await HapticEngine.create();
/// await engine.start();
/// // ...
/// ```
///
/// **Note:** On web/WASM, only the static feedback methods are available.
/// Advanced features (create, patterns, players) throw [UnsupportedError].
class HapticEngine {
  HapticEngine._();

  static HapticServiceBase? _staticService;

  static HapticServiceBase get _service =>
      _staticService ??= HapticServiceFactory.create();

  /// Whether the device supports haptic feedback.
  ///
  /// On iOS/macOS, returns `true` if the device has a Taptic Engine.
  /// On other platforms, returns `true` if Flutter's HapticFeedback is available.
  static Future<bool> get isSupported => _service.isSupported;

  /// Whether advanced Core Haptics features are available.
  ///
  /// Returns `true` on iOS/macOS, `false` on other platforms.
  /// Advanced features include: custom patterns, AHAP files, looping, and dynamic parameters.
  static bool get supportsAdvancedHaptics => _service.supportsAdvancedHaptics;

  /// Trigger a light impact haptic feedback.
  ///
  /// Works on all platforms. On iOS/macOS uses Core Haptics,
  /// on other platforms falls back to Flutter's HapticFeedback.
  static Future<void> lightImpact() => _service.lightImpact();

  /// Trigger a medium impact haptic feedback.
  ///
  /// Works on all platforms. On iOS/macOS uses Core Haptics,
  /// on other platforms falls back to Flutter's HapticFeedback.
  static Future<void> mediumImpact() => _service.mediumImpact();

  /// Trigger a heavy impact haptic feedback.
  ///
  /// Works on all platforms. On iOS/macOS uses Core Haptics,
  /// on other platforms falls back to Flutter's HapticFeedback.
  static Future<void> heavyImpact() => _service.heavyImpact();

  /// Trigger a soft impact haptic feedback.
  ///
  /// On iOS 13.0+ uses native soft impact. On other platforms,
  /// falls back to light impact as the closest equivalent.
  static Future<void> softImpact() => _service.softImpact();

  /// Trigger a rigid impact haptic feedback.
  ///
  /// On iOS 13.0+ uses native rigid impact. On other platforms,
  /// falls back to heavy impact as the closest equivalent.
  static Future<void> rigidImpact() => _service.rigidImpact();

  /// Trigger a success notification haptic feedback.
  ///
  /// On iOS/macOS uses notification feedback generator.
  /// On other platforms, falls back to medium impact.
  static Future<void> success() => _service.success();

  /// Trigger a warning notification haptic feedback.
  ///
  /// On iOS/macOS uses notification feedback generator.
  /// On other platforms, falls back to heavy impact.
  static Future<void> warning() => _service.warning();

  /// Trigger an error notification haptic feedback.
  ///
  /// On iOS/macOS uses notification feedback generator.
  /// On other platforms, falls back to vibrate.
  static Future<void> error() => _service.error();

  /// Trigger a selection change haptic feedback.
  ///
  /// Works on all platforms. On iOS/macOS uses Core Haptics,
  /// on other platforms falls back to Flutter's selectionClick.
  static Future<void> selection() => _service.selection();

  /// Play a custom haptic pattern.
  ///
  /// **Note:** This method requires Core Haptics and only works on iOS/macOS.
  /// On web/WASM, throws [HapticsException] with [HapticsErrorCode.notSupported].
  ///
  /// For cross-platform haptics, use the simpler static methods like
  /// [lightImpact], [mediumImpact], or [success].
  static Future<void> play(List<HapticEvent> events) async {
    throw HapticsException(
      HapticsErrorCode.notSupported,
      'Advanced haptic features (HapticEngine, patterns, players) '
      'are only available on iOS and macOS. '
      'Use static methods like HapticEngine.lightImpact() for cross-platform support.',
    );
  }

  /// Reset static state for testing.
  @visibleForTesting
  static void resetForTest({
    Object? bindings,
    Object? bridge,
    HapticServiceBase? service,
  }) {
    _staticService = service;
  }

  /// Stream of engine lifecycle events.
  Stream<HapticEngineEvent> get events => const Stream.empty();

  /// Create a new engine and optionally register for engine events.
  ///
  /// **Note:** This method requires Core Haptics and only works on iOS/macOS.
  /// On web/WASM, throws [HapticsException] with [HapticsErrorCode.notSupported].
  ///
  /// For cross-platform haptics, use the simpler static methods like
  /// [lightImpact], [mediumImpact], or [success].
  static Future<HapticEngine> create({
    HapticEngineEventHandler? onEvent,
    Object? bridge,
  }) async {
    throw HapticsException(
      HapticsErrorCode.notSupported,
      'Advanced haptic features (HapticEngine, patterns, players) '
      'are only available on iOS and macOS. '
      'Use static methods like HapticEngine.lightImpact() for cross-platform support.',
    );
  }

  /// Start the native Core Haptics engine.
  Future<void> start() async {
    throw HapticsException(
      HapticsErrorCode.notSupported,
      'Advanced haptic features are only available on iOS and macOS.',
    );
  }

  /// Stop the native Core Haptics engine.
  Future<void> stop() async {
    throw HapticsException(
      HapticsErrorCode.notSupported,
      'Advanced haptic features are only available on iOS and macOS.',
    );
  }

  /// Load a pattern from an AHAP JSON string.
  Future<HapticPattern> loadPatternFromAhap(String ahapJson) async {
    throw HapticsException(
      HapticsErrorCode.notSupported,
      'Advanced haptic features are only available on iOS and macOS.',
    );
  }

  /// Load a pattern from raw AHAP bytes.
  Future<HapticPattern> loadPatternFromBytes(Uint8List bytes) async {
    throw HapticsException(
      HapticsErrorCode.notSupported,
      'Advanced haptic features are only available on iOS and macOS.',
    );
  }

  /// Load a pattern from a file on disk.
  Future<HapticPattern> loadPatternFromFile(String path) async {
    throw HapticsException(
      HapticsErrorCode.notSupported,
      'Advanced haptic features are only available on iOS and macOS.',
    );
  }

  /// Build a pattern from a list of programmatic events.
  Future<HapticPattern> loadPatternFromEvents(
    List<HapticEvent> events,
  ) async {
    throw HapticsException(
      HapticsErrorCode.notSupported,
      'Advanced haptic features are only available on iOS and macOS.',
    );
  }

  /// Load a pattern from a Flutter asset.
  Future<HapticPattern> loadPatternFromAsset(
    String asset, {
    AssetBundle? bundle,
  }) async {
    throw HapticsException(
      HapticsErrorCode.notSupported,
      'Advanced haptic features are only available on iOS and macOS.',
    );
  }

  /// Create a player for a given pattern.
  Future<HapticPlayer> createPlayer(HapticPattern pattern) async {
    throw HapticsException(
      HapticsErrorCode.notSupported,
      'Advanced haptic features are only available on iOS and macOS.',
    );
  }

  /// Release engine resources and detach callbacks.
  Future<void> dispose() async {
    // No-op on web
  }
}

/// A Core Haptics pattern loaded from AHAP or programmatic events.
///
/// **Note:** On web/WASM, this class exists for API compatibility but
/// all methods throw [HapticsException] with [HapticsErrorCode.notSupported].
class HapticPattern {
  HapticPattern._();

  /// Original AHAP bytes for inspection or reuse.
  Uint8List get bytes => Uint8List(0);

  /// Load a pattern from AHAP bytes.
  static Future<HapticPattern> fromBytes(
    Uint8List bytes, {
    Object? bridge,
  }) async {
    throw HapticsException(
      HapticsErrorCode.notSupported,
      'Advanced haptic features are only available on iOS and macOS.',
    );
  }

  /// Load a pattern from a file path.
  static Future<HapticPattern> fromFile(
    String path, {
    Object? bridge,
  }) async {
    throw HapticsException(
      HapticsErrorCode.notSupported,
      'Advanced haptic features are only available on iOS and macOS.',
    );
  }

  /// Release the native pattern handle.
  Future<void> dispose() async {
    // No-op on web
  }
}

/// Controls playback of a single haptic pattern.
///
/// **Note:** On web/WASM, this class exists for API compatibility but
/// all methods throw [HapticsException] with [HapticsErrorCode.notSupported].
class HapticPlayer {
  HapticPlayer._();

  /// Strong reference so the native player's pattern is not GC'd early.
  HapticPattern get pattern => HapticPattern._();

  /// Start playback at the given relative time (seconds).
  Future<void> play({double atTime = 0}) async {
    throw HapticsException(
      HapticsErrorCode.notSupported,
      'Advanced haptic features are only available on iOS and macOS.',
    );
  }

  /// Stop playback at the given relative time (seconds).
  Future<void> stop({double atTime = 0}) async {
    throw HapticsException(
      HapticsErrorCode.notSupported,
      'Advanced haptic features are only available on iOS and macOS.',
    );
  }

  /// Enable looping between `loopStart` and `loopEnd` (seconds).
  Future<void> setLoop({
    required bool enabled,
    double loopStart = 0,
    double loopEnd = 0,
  }) async {
    throw HapticsException(
      HapticsErrorCode.notSupported,
      'Advanced haptic features are only available on iOS and macOS.',
    );
  }

  /// Send a dynamic parameter (e.g., intensity/sharpness) at a given time.
  Future<void> setParameter(
    HapticParameterId id,
    double value, {
    double atTime = 0,
  }) async {
    throw HapticsException(
      HapticsErrorCode.notSupported,
      'Advanced haptic features are only available on iOS and macOS.',
    );
  }

  /// Release the native player handle.
  Future<void> dispose() async {
    // No-op on web
  }
}
