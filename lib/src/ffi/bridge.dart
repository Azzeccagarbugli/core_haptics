import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as pkgffi;

import 'bindings.dart';

/// Abstract base class for native bridge implementations.
abstract class NativeBridgeBase {
  /// Get the native bindings.
  NativeBindings get bindings;

  /// Create a new engine handle.
  NativeCallResult<ffi.Pointer<ffi.Void>> engineCreate({
    ffi.Pointer<ffi.NativeFunction<EngineCallbackNative>>? callback,
    ffi.Pointer<ffi.Void>? context,
  });

  /// Start the engine.
  NativeCallResult<void> engineStart(ffi.Pointer<ffi.Void> handle);

  /// Stop the engine.
  NativeCallResult<void> engineStop(ffi.Pointer<ffi.Void> handle);

  /// Release the engine handle.
  void engineRelease(ffi.Pointer<ffi.Void> handle);

  /// Load a pattern from bytes.
  NativeCallResult<ffi.Pointer<ffi.Void>> patternFromBytes(List<int> data);

  /// Load a pattern from a file.
  NativeCallResult<ffi.Pointer<ffi.Void>> patternFromFile(String path);

  /// Release the pattern handle.
  void patternRelease(ffi.Pointer<ffi.Void> handle);

  /// Create a new player handle.
  NativeCallResult<ffi.Pointer<ffi.Void>> playerCreate({
    required ffi.Pointer<ffi.Void> engine,
    required ffi.Pointer<ffi.Void> pattern,
  });

  /// Play the player.
  NativeCallResult<void> playerPlay(
    ffi.Pointer<ffi.Void> player, {
    double atTime,
  });

  /// Stop the player.
  NativeCallResult<void> playerStop(
    ffi.Pointer<ffi.Void> player, {
    double atTime,
  });

  /// Set the loop for the player.
  NativeCallResult<void> playerSetLoop(
    ffi.Pointer<ffi.Void> player, {
    required bool enabled,
    double loopStart,
    double loopEnd,
  });

  /// Send a parameter to the player.
  NativeCallResult<void> playerSendParameter(
    ffi.Pointer<ffi.Void> player, {
    required int parameterId,
    required double value,
    double atTime,
  });

  /// Release the player handle.
  void playerRelease(ffi.Pointer<ffi.Void> handle);
}

/// Result of a native call.
class NativeCallResult<T> {
  /// Create a new native call result.
  const NativeCallResult({
    required this.code,
    this.value,
    this.message,
  });

  /// The code from the native call.
  final int code;

  /// The result of the native call.
  final T? value;

  /// The message from the native call.
  final String? message;

  /// Whether the native call was successful.
  bool get isOk => code == 0;
}

/// Native bridge implementation using the native bindings.
class NativeBridge implements NativeBridgeBase {
  /// Create a new native bridge.
  NativeBridge({NativeBindings? bindings})
      : bindings = bindings ?? NativeBindings();

  @override
  final NativeBindings bindings;

  @override
  NativeCallResult<ffi.Pointer<ffi.Void>> engineCreate({
    ffi.Pointer<ffi.NativeFunction<EngineCallbackNative>>? callback,
    ffi.Pointer<ffi.Void>? context,
  }) {
    final outHandle = pkgffi.calloc<ffi.Pointer<ffi.Void>>();
    final result = _withMessage((msgPtr) {
      final code = bindings.engineCreate(
        outHandle,
        callback ?? ffi.Pointer.fromAddress(0),
        context ?? ffi.Pointer.fromAddress(0),
        msgPtr,
      );
      return NativeCallResult(
        code: code,
        value:
            code == 0 ? outHandle.value : ffi.Pointer<ffi.Void>.fromAddress(0),
        message: null,
      );
    });
    pkgffi.calloc.free(outHandle);
    return result;
  }

  @override
  NativeCallResult<void> engineStart(ffi.Pointer<ffi.Void> handle) =>
      _withMessage((msgPtr) {
        final code = bindings.engineStart(handle, msgPtr);
        return NativeCallResult(code: code, message: null);
      });

  @override
  NativeCallResult<void> engineStop(ffi.Pointer<ffi.Void> handle) =>
      _withMessage((msgPtr) {
        final code = bindings.engineStop(handle, msgPtr);
        return NativeCallResult(code: code, message: null);
      });

  @override
  void engineRelease(ffi.Pointer<ffi.Void> handle) =>
      bindings.engineRelease(handle);

  @override
  NativeCallResult<ffi.Pointer<ffi.Void>> patternFromBytes(List<int> data) {
    final outPattern = pkgffi.calloc<ffi.Pointer<ffi.Void>>();
    final buffer = pkgffi.calloc<ffi.Uint8>(data.length);
    buffer.asTypedList(data.length).setAll(0, data);
    final result = _withMessage((msgPtr) {
      final code = bindings.patternFromData(
        buffer,
        data.length,
        outPattern,
        msgPtr,
      );
      return NativeCallResult(
        code: code,
        value:
            code == 0 ? outPattern.value : ffi.Pointer<ffi.Void>.fromAddress(0),
      );
    });
    pkgffi.calloc.free(buffer);
    pkgffi.calloc.free(outPattern);
    return result;
  }

  @override
  NativeCallResult<ffi.Pointer<ffi.Void>> patternFromFile(String path) {
    final outPattern = pkgffi.calloc<ffi.Pointer<ffi.Void>>();
    final cPath = path.toNativeUtf8();
    final result = _withMessage((msgPtr) {
      final code = bindings.patternFromFile(
        cPath,
        outPattern,
        msgPtr,
      );
      return NativeCallResult(
        code: code,
        value:
            code == 0 ? outPattern.value : ffi.Pointer<ffi.Void>.fromAddress(0),
      );
    });
    pkgffi.calloc.free(cPath);
    pkgffi.calloc.free(outPattern);
    return result;
  }

  @override
  void patternRelease(ffi.Pointer<ffi.Void> handle) =>
      bindings.patternRelease(handle);

  @override
  NativeCallResult<ffi.Pointer<ffi.Void>> playerCreate({
    required ffi.Pointer<ffi.Void> engine,
    required ffi.Pointer<ffi.Void> pattern,
  }) {
    final outPlayer = pkgffi.calloc<ffi.Pointer<ffi.Void>>();
    final result = _withMessage((msgPtr) {
      final code = bindings.playerCreate(engine, pattern, outPlayer, msgPtr);
      return NativeCallResult(
        code: code,
        value:
            code == 0 ? outPlayer.value : ffi.Pointer<ffi.Void>.fromAddress(0),
      );
    });
    pkgffi.calloc.free(outPlayer);
    return result;
  }

  @override
  NativeCallResult<void> playerPlay(
    ffi.Pointer<ffi.Void> player, {
    double atTime = 0,
  }) =>
      _withMessage((msgPtr) {
        final code = bindings.playerPlay(player, atTime, msgPtr);
        return NativeCallResult(code: code);
      });

  @override
  NativeCallResult<void> playerStop(
    ffi.Pointer<ffi.Void> player, {
    double atTime = 0,
  }) =>
      _withMessage((msgPtr) {
        final code = bindings.playerStop(player, atTime, msgPtr);
        return NativeCallResult(code: code);
      });

  @override
  NativeCallResult<void> playerSetLoop(
    ffi.Pointer<ffi.Void> player, {
    required bool enabled,
    double loopStart = 0,
    double loopEnd = 0,
  }) =>
      _withMessage((msgPtr) {
        final code = bindings.playerSetLoop(
          player,
          enabled ? 1 : 0,
          loopStart,
          loopEnd,
          msgPtr,
        );
        return NativeCallResult(code: code);
      });

  @override
  NativeCallResult<void> playerSendParameter(
    ffi.Pointer<ffi.Void> player, {
    required int parameterId,
    required double value,
    double atTime = 0,
  }) =>
      _withMessage((msgPtr) {
        final code = bindings.playerSendParameter(
          player,
          parameterId,
          value,
          atTime,
          msgPtr,
        );
        return NativeCallResult(code: code);
      });

  @override
  void playerRelease(ffi.Pointer<ffi.Void> handle) =>
      bindings.playerRelease(handle);

  NativeCallResult<T> _withMessage<T>(
      NativeCallResult<T> Function(ffi.Pointer<ffi.Pointer<pkgffi.Utf8>>)
          body) {
    final messagePtr = pkgffi.calloc<ffi.Pointer<pkgffi.Utf8>>();
    try {
      final result = body(messagePtr);
      final message =
          messagePtr.value == ffi.Pointer<pkgffi.Utf8>.fromAddress(0)
              ? null
              : messagePtr.value.toDartString();
      if (messagePtr.value != ffi.Pointer<pkgffi.Utf8>.fromAddress(0)) {
        bindings.stringFree(messagePtr.value);
      }
      return NativeCallResult(
        code: result.code,
        value: result.value,
        message: message ?? result.message,
      );
    } finally {
      pkgffi.calloc.free(messagePtr);
    }
  }
}
