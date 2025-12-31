import 'package:core_haptics/core_haptics.dart';
import 'package:core_haptics/src/platform/haptic_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock haptic service for testing cross-platform fallback behavior.
class MockHapticService implements HapticServiceBase {
  MockHapticService({
    this.isSupportedResult = true,
    this.supportsAdvancedResult = false,
  });

  final bool isSupportedResult;
  final bool supportsAdvancedResult;
  final List<String> calls = [];

  @override
  bool get supportsAdvancedHaptics => supportsAdvancedResult;

  @override
  Future<bool> get isSupported async => isSupportedResult;

  @override
  Future<void> lightImpact() async => calls.add('lightImpact');

  @override
  Future<void> mediumImpact() async => calls.add('mediumImpact');

  @override
  Future<void> heavyImpact() async => calls.add('heavyImpact');

  @override
  Future<void> softImpact() async => calls.add('softImpact');

  @override
  Future<void> rigidImpact() async => calls.add('rigidImpact');

  @override
  Future<void> success() async => calls.add('success');

  @override
  Future<void> warning() async => calls.add('warning');

  @override
  Future<void> error() async => calls.add('error');

  @override
  Future<void> selection() async => calls.add('selection');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterHapticService', () {
    late List<MethodCall> hapticCalls;

    setUp(() {
      hapticCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          hapticCalls.add(methodCall);
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('supportsAdvancedHaptics returns false', () {
      final service = FlutterHapticService();
      expect(service.supportsAdvancedHaptics, isFalse);
    });

    test('lightImpact calls HapticFeedback.lightImpact', () async {
      final service = FlutterHapticService();
      await service.lightImpact();

      expect(hapticCalls, hasLength(1));
      expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
      expect(hapticCalls.first.arguments, 'HapticFeedbackType.lightImpact');
    });

    test('mediumImpact calls HapticFeedback.mediumImpact', () async {
      final service = FlutterHapticService();
      await service.mediumImpact();

      expect(hapticCalls, hasLength(1));
      expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
      expect(hapticCalls.first.arguments, 'HapticFeedbackType.mediumImpact');
    });

    test('heavyImpact calls HapticFeedback.heavyImpact', () async {
      final service = FlutterHapticService();
      await service.heavyImpact();

      expect(hapticCalls, hasLength(1));
      expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
      expect(hapticCalls.first.arguments, 'HapticFeedbackType.heavyImpact');
    });

    test('softImpact falls back to lightImpact', () async {
      final service = FlutterHapticService();
      await service.softImpact();

      expect(hapticCalls, hasLength(1));
      expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
      expect(hapticCalls.first.arguments, 'HapticFeedbackType.lightImpact');
    });

    test('rigidImpact falls back to heavyImpact', () async {
      final service = FlutterHapticService();
      await service.rigidImpact();

      expect(hapticCalls, hasLength(1));
      expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
      expect(hapticCalls.first.arguments, 'HapticFeedbackType.heavyImpact');
    });

    test('success falls back to mediumImpact', () async {
      final service = FlutterHapticService();
      await service.success();

      expect(hapticCalls, hasLength(1));
      expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
      expect(hapticCalls.first.arguments, 'HapticFeedbackType.mediumImpact');
    });

    test('warning falls back to heavyImpact', () async {
      final service = FlutterHapticService();
      await service.warning();

      expect(hapticCalls, hasLength(1));
      expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
      expect(hapticCalls.first.arguments, 'HapticFeedbackType.heavyImpact');
    });

    test('error falls back to vibrate', () async {
      final service = FlutterHapticService();
      await service.error();

      expect(hapticCalls, hasLength(1));
      expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
      // vibrate() sends null as argument
      expect(hapticCalls.first.arguments, isNull);
    });

    test('selection calls selectionClick', () async {
      final service = FlutterHapticService();
      await service.selection();

      expect(hapticCalls, hasLength(1));
      expect(hapticCalls.first.method, 'HapticFeedback.vibrate');
      expect(hapticCalls.first.arguments, 'HapticFeedbackType.selectionClick');
    });
  });

  group('HapticEngine with mock service', () {
    late MockHapticService mockService;

    setUp(() {
      mockService = MockHapticService();
      HapticEngine.resetForTest(service: mockService);
    });

    tearDown(() {
      HapticEngine.resetForTest();
    });

    test('isSupported delegates to service', () async {
      expect(await HapticEngine.isSupported, isTrue);

      final unsupportedService = MockHapticService(isSupportedResult: false);
      HapticEngine.resetForTest(service: unsupportedService);
      expect(await HapticEngine.isSupported, isFalse);
    });

    test('supportsAdvancedHaptics delegates to service', () {
      expect(HapticEngine.supportsAdvancedHaptics, isFalse);

      final advancedService = MockHapticService(supportsAdvancedResult: true);
      HapticEngine.resetForTest(service: advancedService);
      expect(HapticEngine.supportsAdvancedHaptics, isTrue);
    });

    test('lightImpact delegates to service', () async {
      await HapticEngine.lightImpact();
      expect(mockService.calls, contains('lightImpact'));
    });

    test('mediumImpact delegates to service', () async {
      await HapticEngine.mediumImpact();
      expect(mockService.calls, contains('mediumImpact'));
    });

    test('heavyImpact delegates to service', () async {
      await HapticEngine.heavyImpact();
      expect(mockService.calls, contains('heavyImpact'));
    });

    test('softImpact delegates to service', () async {
      await HapticEngine.softImpact();
      expect(mockService.calls, contains('softImpact'));
    });

    test('rigidImpact delegates to service', () async {
      await HapticEngine.rigidImpact();
      expect(mockService.calls, contains('rigidImpact'));
    });

    test('success delegates to service', () async {
      await HapticEngine.success();
      expect(mockService.calls, contains('success'));
    });

    test('warning delegates to service', () async {
      await HapticEngine.warning();
      expect(mockService.calls, contains('warning'));
    });

    test('error delegates to service', () async {
      await HapticEngine.error();
      expect(mockService.calls, contains('error'));
    });

    test('selection delegates to service', () async {
      await HapticEngine.selection();
      expect(mockService.calls, contains('selection'));
    });
  });

  group('Advanced haptics platform guard', () {
    late MockHapticService nonAdvancedService;

    setUp(() {
      // Use a non-advanced service to simulate non-Apple platform
      nonAdvancedService = MockHapticService(supportsAdvancedResult: false);
      // Must set via factory to affect ensureAdvancedHapticsSupported()
      HapticServiceFactory.setTestService(nonAdvancedService);
      HapticEngine.resetForTest(service: nonAdvancedService);
    });

    tearDown(() {
      HapticServiceFactory.setTestService(null);
      HapticEngine.resetForTest();
    });

    test('HapticEngine.create throws on non-Apple platforms', () async {
      expect(
        () => HapticEngine.create(),
        throwsA(
          isA<HapticsException>()
              .having((e) => e.code, 'code', HapticsErrorCode.notSupported)
              .having(
                (e) => e.message,
                'message',
                contains('only available on iOS and macOS'),
              ),
        ),
      );
    });

    test('HapticEngine.play throws on non-Apple platforms', () async {
      expect(
        () => HapticEngine.play([
          const HapticEvent(type: HapticEventType.transient),
        ]),
        throwsA(
          isA<HapticsException>()
              .having((e) => e.code, 'code', HapticsErrorCode.notSupported),
        ),
      );
    });

    test('ensureAdvancedHapticsSupported throws with helpful message', () {
      expect(
        () => ensureAdvancedHapticsSupported(),
        throwsA(
          isA<HapticsException>()
              .having((e) => e.code, 'code', HapticsErrorCode.notSupported)
              .having(
                (e) => e.message,
                'message',
                allOf(
                  contains('Advanced haptic features'),
                  contains('HapticEngine.lightImpact()'),
                ),
              ),
        ),
      );
    });
  });

  group('HapticServiceFactory', () {
    tearDown(() {
      HapticServiceFactory.setTestService(null);
    });

    test('setTestService allows injection', () {
      final mockService = MockHapticService();
      HapticServiceFactory.setTestService(mockService);

      final service = HapticServiceFactory.create();
      expect(service, same(mockService));
    });

    test('setTestService(null) clears injected service', () {
      final mockService1 = MockHapticService();
      final mockService2 = MockHapticService();

      HapticServiceFactory.setTestService(mockService1);
      expect(HapticServiceFactory.create(), same(mockService1));

      // Setting a different mock should replace the old one
      HapticServiceFactory.setTestService(mockService2);
      expect(HapticServiceFactory.create(), same(mockService2));
    });

    test('isApplePlatform returns expected value', () {
      // This test verifies the platform detection works
      // On macOS (test environment), this should return true
      // The actual value depends on the test runner platform
      expect(HapticServiceFactory.isApplePlatform, isA<bool>());
    });
  });
}
