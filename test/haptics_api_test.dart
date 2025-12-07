import 'dart:ffi' as ffi;

import 'package:core_haptics/core_haptics.dart';
import 'package:core_haptics/src/ffi/bindings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core_haptics/src/ffi/bridge.dart';
import 'package:ffi/ffi.dart' as pkgffi;

void _noopRelease(ffi.Pointer<ffi.Void> _) {}
int _noopStringFree(ffi.Pointer<pkgffi.Utf8> _) => 0;

final ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>
    _noopReleasePtr =
    ffi.Pointer.fromFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>(
        _noopRelease);

NativeBindings _makeTestBindings() {
  int alwaysOkCreate(
    ffi.Pointer<ffi.Pointer<ffi.Void>> _,
    ffi.Pointer<ffi.NativeFunction<EngineCallbackNative>> __,
    ffi.Pointer<ffi.Void> ___,
    Utf8PointerPtr ____,
  ) =>
      0;

  int alwaysOkStartStop(
    ffi.Pointer<ffi.Void> _,
    Utf8PointerPtr __,
  ) =>
      0;

  int alwaysOkPatternFromData(
    ffi.Pointer<ffi.Uint8> _,
    int __,
    ffi.Pointer<ffi.Pointer<ffi.Void>> ___,
    Utf8PointerPtr ____,
  ) =>
      0;

  int alwaysOkPatternFromFile(
    Utf8Ptr _,
    ffi.Pointer<ffi.Pointer<ffi.Void>> __,
    Utf8PointerPtr ___,
  ) =>
      0;

  int alwaysOkPlayerCreate(
    ffi.Pointer<ffi.Void> _,
    ffi.Pointer<ffi.Void> __,
    ffi.Pointer<ffi.Pointer<ffi.Void>> ___,
    Utf8PointerPtr ____,
  ) =>
      0;

  int alwaysOkPlayStop(
    ffi.Pointer<ffi.Void> _,
    double __,
    Utf8PointerPtr ___,
  ) =>
      0;

  int alwaysOkLoop(
    ffi.Pointer<ffi.Void> _,
    int __,
    double ___,
    double ____,
    Utf8PointerPtr _____,
  ) =>
      0;

  int alwaysOkParameter(
    ffi.Pointer<ffi.Void> _,
    int __,
    double ___,
    double ____,
    Utf8PointerPtr _____,
  ) =>
      0;

  return NativeBindings.test(
    engineReleasePtr: _noopReleasePtr,
    patternReleasePtr: _noopReleasePtr,
    playerReleasePtr: _noopReleasePtr,
    engineCreate: alwaysOkCreate,
    engineStart: alwaysOkStartStop,
    engineStop: alwaysOkStartStop,
    patternFromData: alwaysOkPatternFromData,
    patternFromFile: alwaysOkPatternFromFile,
    playerCreate: alwaysOkPlayerCreate,
    playerPlay: alwaysOkPlayStop,
    playerStop: alwaysOkPlayStop,
    playerSetLoop: alwaysOkLoop,
    playerSendParameter: alwaysOkParameter,
    engineRelease: _noopRelease,
    patternRelease: _noopRelease,
    playerRelease: _noopRelease,
    stringFree: _noopStringFree,
  );
}

class FakeBridge implements NativeBridgeBase {
  FakeBridge({
    this.engineCreateCode = 0,
    this.startCode = 0,
    this.parameterCode = 0,
  }) {
    bindings = _makeTestBindings();
  }

  @override
  late final NativeBindings bindings;

  int engineCreateCode;
  int startCode;
  int parameterCode;

  int _nextHandle = 1;
  final List<String> calls = [];
  final List<int> releasedHandles = [];

  ffi.Pointer<ffi.Void> _newHandle() => ffi.Pointer.fromAddress(_nextHandle++);

  @override
  NativeCallResult<ffi.Pointer<ffi.Void>> engineCreate({
    ffi.Pointer<ffi.NativeFunction<EngineCallbackNative>>? callback,
    ffi.Pointer<ffi.Void>? context,
  }) {
    calls.add('engineCreate');
    if (engineCreateCode != 0) {
      return NativeCallResult(
        code: engineCreateCode,
        message: 'create-error',
      );
    }
    return NativeCallResult(code: 0, value: _newHandle());
  }

  @override
  NativeCallResult<void> engineStart(ffi.Pointer<ffi.Void> handle) {
    calls.add('engineStart:${handle.address}');
    return NativeCallResult(code: startCode);
  }

  @override
  NativeCallResult<void> engineStop(ffi.Pointer<ffi.Void> handle) {
    calls.add('engineStop:${handle.address}');
    return const NativeCallResult(code: 0);
  }

  @override
  void engineRelease(ffi.Pointer<ffi.Void> handle) {
    calls.add('engineRelease:${handle.address}');
    releasedHandles.add(handle.address);
  }

  @override
  NativeCallResult<ffi.Pointer<ffi.Void>> patternFromBytes(List<int> data) {
    calls.add('patternFromBytes:${data.length}');
    return NativeCallResult(code: 0, value: _newHandle());
  }

  @override
  NativeCallResult<ffi.Pointer<ffi.Void>> patternFromFile(String path) {
    calls.add('patternFromFile:$path');
    return NativeCallResult(code: 0, value: _newHandle());
  }

  @override
  void patternRelease(ffi.Pointer<ffi.Void> handle) {
    calls.add('patternRelease:${handle.address}');
    releasedHandles.add(handle.address);
  }

  @override
  NativeCallResult<ffi.Pointer<ffi.Void>> playerCreate({
    required ffi.Pointer<ffi.Void> engine,
    required ffi.Pointer<ffi.Void> pattern,
  }) {
    calls.add('playerCreate:${engine.address}:${pattern.address}');
    return NativeCallResult(code: 0, value: _newHandle());
  }

  @override
  NativeCallResult<void> playerPlay(
    ffi.Pointer<ffi.Void> player, {
    double atTime = 0,
  }) {
    calls.add('playerPlay:${player.address}:$atTime');
    return const NativeCallResult(code: 0);
  }

  @override
  NativeCallResult<void> playerStop(
    ffi.Pointer<ffi.Void> player, {
    double atTime = 0,
  }) {
    calls.add('playerStop:${player.address}:$atTime');
    return const NativeCallResult(code: 0);
  }

  @override
  NativeCallResult<void> playerSetLoop(
    ffi.Pointer<ffi.Void> player, {
    required bool enabled,
    double loopStart = 0,
    double loopEnd = 0,
  }) {
    calls.add('playerSetLoop:${player.address}:$enabled:$loopStart:$loopEnd');
    return const NativeCallResult(code: 0);
  }

  @override
  NativeCallResult<void> playerSendParameter(
    ffi.Pointer<ffi.Void> player, {
    required int parameterId,
    required double value,
    double atTime = 0,
  }) {
    calls.add('playerParameter:${player.address}:$parameterId:$value:$atTime');
    if (parameterCode != 0) {
      return NativeCallResult(code: parameterCode, message: 'param-error');
    }
    return const NativeCallResult(code: 0);
  }

  @override
  void playerRelease(ffi.Pointer<ffi.Void> handle) {
    calls.add('playerRelease:${handle.address}');
    releasedHandles.add(handle.address);
  }
}

class FakeAssetBundle extends CachingAssetBundle {
  FakeAssetBundle(this.bytes);
  final Uint8List bytes;

  @override
  Future<ByteData> load(String key) async {
    return ByteData.view(bytes.buffer);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('engine lifecycle succeeds and disposes', () async {
    final bridge = FakeBridge();
    final engine = await HapticEngine.create(bridge: bridge);
    await engine.start();
    await engine.stop();
    await engine.dispose();

    expect(
      bridge.calls,
      containsAllInOrder([
        'engineCreate',
        startsWith('engineStart'),
        startsWith('engineStop'),
        startsWith('engineRelease'),
      ]),
    );
    expect(bridge.releasedHandles, isNotEmpty);
  });

  test('player lifecycle, parameter, and loop', () async {
    final bridge = FakeBridge();
    final engine = await HapticEngine.create(bridge: bridge);
    final pattern = await engine.loadPatternFromAhap('{"Version":1}');
    final player = await engine.createPlayer(pattern);

    await player.play();
    await player.setLoop(enabled: true, loopStart: 0, loopEnd: 1);
    await player.setParameter(HapticParameterId.hapticIntensity, 0.5);
    await player.stop();
    await player.dispose();
    await engine.dispose();

    expect(
      bridge.calls,
      containsAll([
        startsWith('patternFromBytes'),
        startsWith('playerCreate'),
        startsWith('playerPlay'),
        startsWith('playerSetLoop'),
        startsWith('playerParameter'),
        startsWith('playerStop'),
        startsWith('playerRelease'),
      ]),
    );
  });

  test('build pattern from events matches AHAP flow', () async {
    final bridge = FakeBridge();
    final engine = await HapticEngine.create(bridge: bridge);
    final events = [
      const HapticEvent(
        type: HapticEventType.transient,
        time: Duration.zero,
        intensity: 1.0,
        sharpness: 0.5,
      ),
      const HapticEvent(
        type: HapticEventType.continuous,
        time: Duration(milliseconds: 100),
        duration: Duration(milliseconds: 500),
        intensity: 0.7,
        sharpness: 0.3,
      ),
    ];
    final pattern = await engine.loadPatternFromEvents(events);
    expect(pattern.bytes.isNotEmpty, isTrue);
    expect(
      bridge.calls,
      contains(predicate<String>((c) => c.startsWith('patternFromBytes'))),
    );
    await engine.dispose();
  });

  test('load pattern from asset uses provided bundle', () async {
    final bridge = FakeBridge();
    final engine = await HapticEngine.create(bridge: bridge);
    final fakeBundle = FakeAssetBundle(Uint8List.fromList('{ }'.codeUnits));
    final pattern =
        await engine.loadPatternFromAsset('test.ahap', bundle: fakeBundle);
    expect(pattern.bytes, isNotEmpty);
    await engine.dispose();
  });

  test('errors propagate as HapticsException', () async {
    final bridge = FakeBridge(startCode: 2);
    final engine = await HapticEngine.create(bridge: bridge);
    expect(
      () => engine.start(),
      throwsA(isA<HapticsException>()
          .having((e) => e.code, 'code', HapticsErrorCode.engine)),
    );
    await engine.dispose();
  });

  test('parameter error bubbles up', () async {
    final bridge = FakeBridge(parameterCode: 4);
    final engine = await HapticEngine.create(bridge: bridge);
    final pattern = await engine.loadPatternFromAhap('{"Version":1}');
    final player = await engine.createPlayer(pattern);
    expect(
      () => player.setParameter(HapticParameterId.audioPitch, 0.1),
      throwsA(isA<HapticsException>()
          .having((e) => e.code, 'code', HapticsErrorCode.invalidArgument)),
    );
    await engine.dispose();
  });
}
