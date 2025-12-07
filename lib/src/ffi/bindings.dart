import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as pkgffi;

import 'native_library.dart';

/// Pointer to a UTF-8 string.
typedef Utf8Ptr = ffi.Pointer<pkgffi.Utf8>;

/// Pointer to a pointer to a UTF-8 string.
typedef Utf8PointerPtr = ffi.Pointer<ffi.Pointer<pkgffi.Utf8>>;

/// Native callback function for engine events.
typedef EngineCallbackNative = ffi.Void Function(
  ffi.Int32 eventCode,
  Utf8Ptr message,
  ffi.Pointer<ffi.Void> context,
);

/// Native bindings for the Core Haptics library.
class NativeBindings {
  /// Create a new native bindings instance.
  NativeBindings({ffi.DynamicLibrary? library})
      : _lib = library ?? loadCoreHapticsLibrary() {
    _engineCreate = _lib.lookupFunction<
        ffi.Int32 Function(
          ffi.Pointer<ffi.Pointer<ffi.Void>>,
          ffi.Pointer<ffi.NativeFunction<EngineCallbackNative>>,
          ffi.Pointer<ffi.Void>,
          Utf8PointerPtr,
        ),
        int Function(
          ffi.Pointer<ffi.Pointer<ffi.Void>>,
          ffi.Pointer<ffi.NativeFunction<EngineCallbackNative>>,
          ffi.Pointer<ffi.Void>,
          Utf8PointerPtr,
        )>('chffi_engine_create');

    _engineStart = _lib.lookupFunction<
        ffi.Int32 Function(
          ffi.Pointer<ffi.Void>,
          Utf8PointerPtr,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          Utf8PointerPtr,
        )>('chffi_engine_start');

    _engineStop = _lib.lookupFunction<
        ffi.Int32 Function(
          ffi.Pointer<ffi.Void>,
          Utf8PointerPtr,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          Utf8PointerPtr,
        )>('chffi_engine_stop');

    engineReleasePtr = _lib
        .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>(
            'chffi_engine_release');
    _engineRelease = _lib.lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Void>),
        void Function(ffi.Pointer<ffi.Void>)>('chffi_engine_release');

    _patternFromData = _lib.lookupFunction<
        ffi.Int32 Function(
          ffi.Pointer<ffi.Uint8>,
          ffi.Int32,
          ffi.Pointer<ffi.Pointer<ffi.Void>>,
          Utf8PointerPtr,
        ),
        int Function(
          ffi.Pointer<ffi.Uint8>,
          int,
          ffi.Pointer<ffi.Pointer<ffi.Void>>,
          Utf8PointerPtr,
        )>('chffi_pattern_from_ahap_data');

    _patternFromFile = _lib.lookupFunction<
        ffi.Int32 Function(
          Utf8Ptr,
          ffi.Pointer<ffi.Pointer<ffi.Void>>,
          Utf8PointerPtr,
        ),
        int Function(
          Utf8Ptr,
          ffi.Pointer<ffi.Pointer<ffi.Void>>,
          Utf8PointerPtr,
        )>('chffi_pattern_from_ahap_file');

    patternReleasePtr = _lib
        .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>(
            'chffi_pattern_release');
    _patternRelease = _lib.lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Void>),
        void Function(ffi.Pointer<ffi.Void>)>('chffi_pattern_release');

    _playerCreate = _lib.lookupFunction<
        ffi.Int32 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Pointer<ffi.Void>>,
          Utf8PointerPtr,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Pointer<ffi.Void>>,
          Utf8PointerPtr,
        )>('chffi_player_create');

    _playerPlay = _lib.lookupFunction<
        ffi.Int32 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Double,
          Utf8PointerPtr,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          double,
          Utf8PointerPtr,
        )>('chffi_player_play');

    _playerStop = _lib.lookupFunction<
        ffi.Int32 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Double,
          Utf8PointerPtr,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          double,
          Utf8PointerPtr,
        )>('chffi_player_stop');

    _playerSetLoop = _lib.lookupFunction<
        ffi.Int32 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Int32,
          ffi.Double,
          ffi.Double,
          Utf8PointerPtr,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          int,
          double,
          double,
          Utf8PointerPtr,
        )>('chffi_player_set_loop');

    _playerSendParameter = _lib.lookupFunction<
        ffi.Int32 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Int32,
          ffi.Double,
          ffi.Double,
          Utf8PointerPtr,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          int,
          double,
          double,
          Utf8PointerPtr,
        )>('chffi_player_send_parameter');

    playerReleasePtr = _lib
        .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>(
            'chffi_player_release');
    _playerRelease = _lib.lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Void>),
        void Function(ffi.Pointer<ffi.Void>)>('chffi_player_release');

    _stringFree =
        _lib.lookupFunction<ffi.Int32 Function(Utf8Ptr), int Function(Utf8Ptr)>(
            'chffi_string_free');
  }

  /// Create a new native bindings instance for testing.
  NativeBindings.test({
    required this.engineReleasePtr,
    required this.patternReleasePtr,
    required this.playerReleasePtr,
    required int Function(
      ffi.Pointer<ffi.Pointer<ffi.Void>>,
      ffi.Pointer<ffi.NativeFunction<EngineCallbackNative>>,
      ffi.Pointer<ffi.Void>,
      Utf8PointerPtr,
    ) engineCreate,
    required int Function(
      ffi.Pointer<ffi.Void>,
      Utf8PointerPtr,
    ) engineStart,
    required int Function(
      ffi.Pointer<ffi.Void>,
      Utf8PointerPtr,
    ) engineStop,
    required int Function(
      ffi.Pointer<ffi.Uint8>,
      int,
      ffi.Pointer<ffi.Pointer<ffi.Void>>,
      Utf8PointerPtr,
    ) patternFromData,
    required int Function(
      Utf8Ptr,
      ffi.Pointer<ffi.Pointer<ffi.Void>>,
      Utf8PointerPtr,
    ) patternFromFile,
    required int Function(
      ffi.Pointer<ffi.Void>,
      ffi.Pointer<ffi.Void>,
      ffi.Pointer<ffi.Pointer<ffi.Void>>,
      Utf8PointerPtr,
    ) playerCreate,
    required int Function(
      ffi.Pointer<ffi.Void>,
      double,
      Utf8PointerPtr,
    ) playerPlay,
    required int Function(
      ffi.Pointer<ffi.Void>,
      double,
      Utf8PointerPtr,
    ) playerStop,
    required int Function(
      ffi.Pointer<ffi.Void>,
      int,
      double,
      double,
      Utf8PointerPtr,
    ) playerSetLoop,
    required int Function(
      ffi.Pointer<ffi.Void>,
      int,
      double,
      double,
      Utf8PointerPtr,
    ) playerSendParameter,
    required void Function(ffi.Pointer<ffi.Void>) engineRelease,
    required void Function(ffi.Pointer<ffi.Void>) patternRelease,
    required void Function(ffi.Pointer<ffi.Void>) playerRelease,
    required int Function(Utf8Ptr) stringFree,
  }) : _lib = ffi.DynamicLibrary.process() {
    _engineCreate = engineCreate;
    _engineStart = engineStart;
    _engineStop = engineStop;
    _patternFromData = patternFromData;
    _patternFromFile = patternFromFile;
    _playerCreate = playerCreate;
    _playerPlay = playerPlay;
    _playerStop = playerStop;
    _playerSetLoop = playerSetLoop;
    _playerSendParameter = playerSendParameter;
    _engineRelease = engineRelease;
    _patternRelease = patternRelease;
    _playerRelease = playerRelease;
    _stringFree = stringFree;
  }

  final ffi.DynamicLibrary _lib;

  late final int Function(
    ffi.Pointer<ffi.Pointer<ffi.Void>>,
    ffi.Pointer<ffi.NativeFunction<EngineCallbackNative>>,
    ffi.Pointer<ffi.Void>,
    Utf8PointerPtr,
  ) _engineCreate;

  late final int Function(
    ffi.Pointer<ffi.Void>,
    Utf8PointerPtr,
  ) _engineStart;

  late final int Function(
    ffi.Pointer<ffi.Void>,
    Utf8PointerPtr,
  ) _engineStop;

  late final void Function(ffi.Pointer<ffi.Void>) _engineRelease;

  late final int Function(
    ffi.Pointer<ffi.Uint8>,
    int,
    ffi.Pointer<ffi.Pointer<ffi.Void>>,
    Utf8PointerPtr,
  ) _patternFromData;

  late final int Function(
    Utf8Ptr,
    ffi.Pointer<ffi.Pointer<ffi.Void>>,
    Utf8PointerPtr,
  ) _patternFromFile;

  late final void Function(ffi.Pointer<ffi.Void>) _patternRelease;

  late final int Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Pointer<ffi.Void>>,
    Utf8PointerPtr,
  ) _playerCreate;

  late final int Function(
    ffi.Pointer<ffi.Void>,
    double,
    Utf8PointerPtr,
  ) _playerPlay;

  late final int Function(
    ffi.Pointer<ffi.Void>,
    double,
    Utf8PointerPtr,
  ) _playerStop;

  late final int Function(
    ffi.Pointer<ffi.Void>,
    int,
    double,
    double,
    Utf8PointerPtr,
  ) _playerSetLoop;

  late final int Function(
    ffi.Pointer<ffi.Void>,
    int,
    double,
    double,
    Utf8PointerPtr,
  ) _playerSendParameter;

  late final void Function(ffi.Pointer<ffi.Void>) _playerRelease;

  late final int Function(Utf8Ptr) _stringFree;

  /// Pointer to the native function for releasing an engine handle.
  late final ffi
      .Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>
      engineReleasePtr;

  /// Pointer to the native function for releasing a pattern handle.
  late final ffi
      .Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>
      patternReleasePtr;

  /// Pointer to the native function for releasing a player handle.
  late final ffi
      .Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>
      playerReleasePtr;

  /// Create a new engine handle.
  int engineCreate(
    ffi.Pointer<ffi.Pointer<ffi.Void>> outHandle,
    ffi.Pointer<ffi.NativeFunction<EngineCallbackNative>> callback,
    ffi.Pointer<ffi.Void> context,
    Utf8PointerPtr message,
  ) =>
      _engineCreate(outHandle, callback, context, message);

  /// Start the engine.
  int engineStart(
    ffi.Pointer<ffi.Void> handle,
    Utf8PointerPtr message,
  ) =>
      _engineStart(handle, message);

  /// Stop the engine.
  int engineStop(
    ffi.Pointer<ffi.Void> handle,
    Utf8PointerPtr message,
  ) =>
      _engineStop(handle, message);

  /// Release the engine handle.
  void engineRelease(ffi.Pointer<ffi.Void> handle) => _engineRelease(handle);

  /// Load a pattern from data.
  int patternFromData(
    ffi.Pointer<ffi.Uint8> bytes,
    int length,
    ffi.Pointer<ffi.Pointer<ffi.Void>> outPattern,
    Utf8PointerPtr message,
  ) =>
      _patternFromData(bytes, length, outPattern, message);

  /// Load a pattern from a file.
  int patternFromFile(
    Utf8Ptr path,
    ffi.Pointer<ffi.Pointer<ffi.Void>> outPattern,
    Utf8PointerPtr message,
  ) =>
      _patternFromFile(path, outPattern, message);

  /// Release the pattern handle.
  void patternRelease(ffi.Pointer<ffi.Void> handle) => _patternRelease(handle);

  /// Create a new player handle.
  int playerCreate(
    ffi.Pointer<ffi.Void> engine,
    ffi.Pointer<ffi.Void> pattern,
    ffi.Pointer<ffi.Pointer<ffi.Void>> outPlayer,
    Utf8PointerPtr message,
  ) =>
      _playerCreate(engine, pattern, outPlayer, message);

  /// Play the player.
  int playerPlay(
    ffi.Pointer<ffi.Void> player,
    double atTime,
    Utf8PointerPtr message,
  ) =>
      _playerPlay(player, atTime, message);

  /// Stop the player.
  int playerStop(
    ffi.Pointer<ffi.Void> player,
    double atTime,
    Utf8PointerPtr message,
  ) =>
      _playerStop(player, atTime, message);

  /// Set the loop for the player.
  int playerSetLoop(
    ffi.Pointer<ffi.Void> player,
    int enabled,
    double loopStart,
    double loopEnd,
    Utf8PointerPtr message,
  ) =>
      _playerSetLoop(player, enabled, loopStart, loopEnd, message);

  /// Send a parameter to the player.
  int playerSendParameter(
    ffi.Pointer<ffi.Void> player,
    int parameterId,
    double value,
    double atTime,
    Utf8PointerPtr message,
  ) =>
      _playerSendParameter(player, parameterId, value, atTime, message);

  /// Release the player handle.
  void playerRelease(ffi.Pointer<ffi.Void> handle) => _playerRelease(handle);

  /// Free a string.
  int stringFree(Utf8Ptr ptr) => _stringFree(ptr);
}
