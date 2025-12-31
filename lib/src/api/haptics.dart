import 'dart:async';
import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as pkgffi;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'dart:convert';

import '../ffi/bridge.dart';
import '../ffi/bindings.dart';
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
class HapticEngine implements ffi.Finalizable {
  HapticEngine._(
    this._bridge,
    this._handle,
    this._contextId,
    this._events,
  ) : _engineFinalizer =
            ffi.NativeFinalizer(_bridge.bindings.engineReleasePtr.cast()) {
    _contextHandlers[_contextId] = _onNativeEvent;
    _engineFinalizer.attach(this, _handle, detach: this);
  }

  static int _nextContextId = 1;
  static final Map<int, void Function(int, String?)> _contextHandlers = {};

  static NativeBindings? _staticBindings;
  static HapticEngine? _sharedEngine;
  static NativeBridgeBase? _staticBridge;
  static HapticServiceBase? _staticService;

  static HapticServiceBase get _service =>
      _staticService ??= HapticServiceFactory.create(bindings: _staticBindings);

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
  /// Creates a shared engine (reused across calls), loads the pattern,
  /// plays it, and cleans up the player and pattern.
  ///
  /// **Note:** This method requires Core Haptics and only works on iOS/macOS.
  /// On other platforms, throws [HapticsException] with [HapticsErrorCode.notSupported].
  ///
  /// For cross-platform haptics, use the simpler static methods like
  /// [lightImpact], [mediumImpact], or [success].
  ///
  /// For more control, use [HapticEngine.create] directly.
  static Future<void> play(List<HapticEvent> events) async {
    ensureAdvancedHapticsSupported();
    if (!await isSupported) return;
    _sharedEngine ??= await HapticEngine.create(bridge: _staticBridge);
    await _sharedEngine!.start();
    final pattern = await _sharedEngine!.loadPatternFromEvents(events);
    final player = await _sharedEngine!.createPlayer(pattern);
    await player.play();
    await player.dispose();
    await pattern.dispose();
  }

  /// Reset static state for testing.
  @visibleForTesting
  static void resetForTest({
    NativeBindings? bindings,
    NativeBridgeBase? bridge,
    HapticServiceBase? service,
  }) {
    _staticBindings = bindings;
    _staticBridge = bridge;
    _staticService = service;
    _sharedEngine = null;
  }

  final NativeBridgeBase _bridge;
  final ffi.Pointer<ffi.Void> _handle;
  final int _contextId;
  final StreamController<HapticEngineEvent> _events;
  final ffi.NativeFinalizer _engineFinalizer;
  HapticEngineEventHandler? _onEvent;
  bool _disposed = false;

  static final ffi.NativeCallable<EngineCallbackNative> _callbackTrampoline =
      ffi.NativeCallable<EngineCallbackNative>.isolateLocal(
          _nativeEventCallback);

  static void _nativeEventCallback(
    int eventCode,
    ffi.Pointer<pkgffi.Utf8> message,
    ffi.Pointer<ffi.Void> context,
  ) {
    final handler = _contextHandlers[context.address];
    if (handler != null) {
      final text = message == ffi.Pointer<pkgffi.Utf8>.fromAddress(0)
          ? null
          : message.toDartString();
      handler(eventCode, text);
    }
  }

  /// Create a new engine and optionally register for engine events.
  ///
  /// **Note:** This method requires Core Haptics and only works on iOS/macOS.
  /// On other platforms, throws [HapticsException] with [HapticsErrorCode.notSupported].
  ///
  /// For cross-platform haptics, use the simpler static methods like
  /// [lightImpact], [mediumImpact], or [success].
  static Future<HapticEngine> create({
    HapticEngineEventHandler? onEvent,
    NativeBridgeBase? bridge,
  }) async {
    ensureAdvancedHapticsSupported();
    final nativeBridge = bridge ?? NativeBridge();
    final contextId = _nextContextId++;
    final events = StreamController<HapticEngineEvent>.broadcast();
    final result = nativeBridge.engineCreate(
      callback: _callbackTrampoline.nativeFunction,
      context: ffi.Pointer.fromAddress(contextId),
    );
    _throwIfError(result);
    final handle = result.value;
    if (handle == null || handle == ffi.Pointer<ffi.Void>.fromAddress(0)) {
      throw HapticsException(HapticsErrorCode.engine, 'Engine handle missing');
    }
    final engine = HapticEngine._(
      nativeBridge,
      handle,
      contextId,
      events,
    );
    engine._onEvent = onEvent;
    return engine;
  }

  /// Stream of engine lifecycle events.
  Stream<HapticEngineEvent> get events => _events.stream;

  /// Start the native Core Haptics engine.
  Future<void> start() async {
    _throwIfError(_bridge.engineStart(_handle));
  }

  /// Stop the native Core Haptics engine.
  Future<void> stop() async {
    _throwIfError(_bridge.engineStop(_handle));
  }

  /// Load a pattern from an AHAP JSON string.
  Future<HapticPattern> loadPatternFromAhap(String ahapJson) async {
    return HapticPattern.fromBytes(
      Uint8List.fromList(ahapJson.codeUnits),
      bridge: _bridge,
    );
  }

  /// Load a pattern from raw AHAP bytes.
  Future<HapticPattern> loadPatternFromBytes(Uint8List bytes) async {
    return HapticPattern.fromBytes(bytes, bridge: _bridge);
  }

  /// Load a pattern from a file on disk.
  Future<HapticPattern> loadPatternFromFile(String path) async {
    return HapticPattern.fromFile(path, bridge: _bridge);
  }

  /// Build a pattern from a list of programmatic events.
  Future<HapticPattern> loadPatternFromEvents(
    List<HapticEvent> events,
  ) async {
    final ahap = _eventsToAhap(events);
    return loadPatternFromAhap(ahap);
  }

  /// Load a pattern from a Flutter asset.
  Future<HapticPattern> loadPatternFromAsset(
    String asset, {
    AssetBundle? bundle,
  }) async {
    final data = await (bundle ?? rootBundle).load(asset);
    return HapticPattern.fromBytes(data.buffer.asUint8List(), bridge: _bridge);
  }

  /// Create a player for a given pattern.
  Future<HapticPlayer> createPlayer(HapticPattern pattern) async {
    final result = _bridge.playerCreate(
      engine: _handle,
      pattern: pattern._handle,
    );
    _throwIfError(result);
    final handle = result.value;
    if (handle == null || handle == ffi.Pointer<ffi.Void>.fromAddress(0)) {
      throw HapticsException(
        HapticsErrorCode.player,
        'Player handle missing',
      );
    }
    return HapticPlayer._(
      bridge: _bridge,
      handle: handle,
      pattern: pattern,
    );
  }

  /// Release engine resources and detach callbacks.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _contextHandlers.remove(_contextId);
    _engineFinalizer.detach(this);
    _bridge.engineRelease(_handle);
    await _events.close();
  }

  void _onNativeEvent(int eventCode, String? message) {
    final event = _mapEvent(eventCode);
    _onEvent?.call(event, message);
    _events.add(event);
  }

  static HapticEngineEvent _mapEvent(int code) {
    switch (code) {
      case 1:
        return HapticEngineEvent.stopped;
      case 2:
        return HapticEngineEvent.reset;
      case 3:
        return HapticEngineEvent.interrupted;
      case 4:
        return HapticEngineEvent.restarted;
      default:
        return HapticEngineEvent.stopped;
    }
  }

  String _eventsToAhap(List<HapticEvent> events) {
    final pattern = events.map((e) => e.toAhapEvent()).toList();
    final map = {
      'Version': 1,
      'Pattern': pattern,
    };
    return _encodeJson(map);
  }

  String _encodeJson(Map<String, dynamic> map) {
    return const JsonEncoder().convert(map);
  }
}

/// A Core Haptics pattern loaded from AHAP or programmatic events.
class HapticPattern implements ffi.Finalizable {
  HapticPattern._(
    this._bridge,
    this._handle,
    this.bytes,
  ) : _finalizer =
            ffi.NativeFinalizer(_bridge.bindings.patternReleasePtr.cast()) {
    _finalizer.attach(this, _handle, detach: this);
  }

  final NativeBridgeBase _bridge;
  final ffi.Pointer<ffi.Void> _handle;

  /// Original AHAP bytes for inspection or reuse.
  final Uint8List bytes;
  final ffi.NativeFinalizer _finalizer;
  bool _disposed = false;

  /// Load a pattern from AHAP bytes.
  static Future<HapticPattern> fromBytes(
    Uint8List bytes, {
    NativeBridgeBase? bridge,
  }) async {
    final b = bridge ?? NativeBridge();
    final result = b.patternFromBytes(bytes);
    _throwIfError(result);
    final handle = result.value;
    if (handle == null || handle == ffi.Pointer<ffi.Void>.fromAddress(0)) {
      throw HapticsException(
        HapticsErrorCode.pattern,
        'Pattern handle missing',
      );
    }
    return HapticPattern._(b, handle, bytes);
  }

  /// Load a pattern from a file path.
  static Future<HapticPattern> fromFile(
    String path, {
    NativeBridgeBase? bridge,
  }) async {
    final b = bridge ?? NativeBridge();
    final result = b.patternFromFile(path);
    _throwIfError(result);
    final handle = result.value;
    if (handle == null || handle == ffi.Pointer<ffi.Void>.fromAddress(0)) {
      throw HapticsException(
        HapticsErrorCode.pattern,
        'Pattern handle missing',
      );
    }
    return HapticPattern._(b, handle, Uint8List(0));
  }

  /// Release the native pattern handle.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _finalizer.detach(this);
    _bridge.patternRelease(_handle);
  }
}

/// Controls playback of a single haptic pattern.
class HapticPlayer implements ffi.Finalizable {
  HapticPlayer._({
    required NativeBridgeBase bridge,
    required ffi.Pointer<ffi.Void> handle,
    required this.pattern,
  })  : _bridge = bridge,
        _handle = handle,
        _finalizer =
            ffi.NativeFinalizer(bridge.bindings.playerReleasePtr.cast()) {
    _finalizer.attach(this, _handle, detach: this);
  }

  final NativeBridgeBase _bridge;
  final ffi.Pointer<ffi.Void> _handle;

  /// Strong reference so the native player’s pattern is not GC’d early.
  final HapticPattern pattern;
  final ffi.NativeFinalizer _finalizer;
  bool _disposed = false;

  /// Start playback at the given relative time (seconds).
  Future<void> play({double atTime = 0}) async {
    _throwIfError(_bridge.playerPlay(_handle, atTime: atTime));
  }

  /// Stop playback at the given relative time (seconds).
  Future<void> stop({double atTime = 0}) async {
    _throwIfError(_bridge.playerStop(_handle, atTime: atTime));
  }

  /// Enable looping between `loopStart` and `loopEnd` (seconds).
  Future<void> setLoop({
    required bool enabled,
    double loopStart = 0,
    double loopEnd = 0,
  }) async {
    _throwIfError(_bridge.playerSetLoop(
      _handle,
      enabled: enabled,
      loopStart: loopStart,
      loopEnd: loopEnd,
    ));
  }

  /// Send a dynamic parameter (e.g., intensity/sharpness) at a given time.
  Future<void> setParameter(
    HapticParameterId id,
    double value, {
    double atTime = 0,
  }) async {
    _throwIfError(_bridge.playerSendParameter(
      _handle,
      parameterId: id.id,
      value: value,
      atTime: atTime,
    ));
  }

  /// Release the native player handle.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _finalizer.detach(this);
    _bridge.playerRelease(_handle);
  }
}

void _throwIfError<T>(NativeCallResult<T> result) {
  if (result.isOk) {
    return;
  }
  throw HapticsException(
    HapticsErrorCode.fromNative(result.code),
    result.message,
  );
}
