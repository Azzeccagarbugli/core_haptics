import 'package:flutter/cupertino.dart';

import 'package:core_haptics/core_haptics.dart';

void main() => runApp(const _App());

class _App extends StatefulWidget {
  const _App();

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  HapticEngine? _engine;
  HapticPattern? _assetPattern;
  HapticPattern? _eventsPattern;
  HapticPattern? _inlinePattern;
  HapticPlayer? _continuousPlayer;
  double _eventsPatternDurationSec = 0;
  String _status = 'Idle';
  String? _lastEvent;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _status = 'Starting engine...');
    try {
      final engine = await HapticEngine.create(
        onEvent: (event, msg) {
          setState(() {
            _lastEvent = '${event.name}${msg != null ? ': $msg' : ''}';
          });
        },
      );
      await engine.start();
      _engine = engine;

      _assetPattern = await engine.loadPatternFromAsset(
        'assets/patterns/transient.ahap',
      );

      final events = [
        const HapticEvent(
          type: HapticEventType.transient,
          time: Duration.zero,
          duration: Duration(seconds: 1),
          intensity: 0.1,
          sharpness: 0.4,
        ),
        const HapticEvent(
          type: HapticEventType.transient,
          time: Duration(seconds: 3),
          intensity: 0.5,
          sharpness: 0.4,
        ),
        const HapticEvent(
          type: HapticEventType.continuous,
          time: Duration(seconds: 10),
          duration: Duration(seconds: 3),
          intensity: 0.7,
          sharpness: 0.3,
        ),
      ];
      _eventsPatternDurationSec = _computeDurationSeconds(events);
      _eventsPattern = await engine.loadPatternFromEvents(events);

      _inlinePattern = await engine.loadPatternFromAhap(_inlineAhap);
      _continuousPlayer = await engine.createPlayer(_eventsPattern!);
      setState(() => _status = 'Ready');
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    }
  }

  double _computeDurationSeconds(List<HapticEvent> events) {
    double maxTime = 0;
    for (final e in events) {
      final start = e.time.inMicroseconds / 1e6;
      final end = start + (e.duration?.inMicroseconds ?? 0) / 1e6;
      if (end > maxTime) maxTime = end;
    }
    return maxTime;
  }

  Future<void> _playOnce(
    HapticPattern? pattern,
    String label, {
    double expectedSeconds = 1,
  }) async {
    if (_busy || _engine == null || pattern == null) return;
    setState(() => _busy = true);
    try {
      final player = await _engine!.createPlayer(pattern);
      await player.play();
      if (expectedSeconds > 0) {
        final waitMs = (expectedSeconds * 1000).round() + 200;
        await Future<void>.delayed(Duration(milliseconds: waitMs));
      }
      await player.dispose();
      setState(() => _status = label);
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _playContinuous() async {
    if (_busy || _continuousPlayer == null) return;
    setState(() => _busy = true);
    try {
      await _continuousPlayer!.play();
      setState(() => _status = 'Continuous playing');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _stopContinuous() async {
    if (_continuousPlayer == null) return;
    await _continuousPlayer!.stop();
    setState(() => _status = 'Continuous stopped');
  }

  Future<void> _setIntensity() async {
    if (_engine == null || _busy) return;
    setState(() => _busy = true);
    try {
      // Build a new pattern with boosted intensity (0.9) baked in.
      final boostedPattern = await _engine!.loadPatternFromEvents([
        HapticEvent(
          type: HapticEventType.continuous,
          duration: const Duration(seconds: 3),
          intensity: 0.9,
          sharpness: 0.5,
        ),
      ]);
      final player = await _engine!.createPlayer(boostedPattern);
      await player.play();
      await player.dispose();
      await boostedPattern.dispose();
      setState(() => _status = 'Played with intensity 0.9');
    } catch (e) {
      setState(() => _status = 'Failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _continuousPlayer?.dispose();
    _assetPattern?.dispose();
    _eventsPattern?.dispose();
    _inlinePattern?.dispose();
    _engine?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = [
      'Status: $_status',
      if (_lastEvent != null) 'Last event: $_lastEvent',
    ].join(' • ');

    return CupertinoApp(
      home: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Core Haptics Demo'),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(info, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                CupertinoButton.filled(
                  onPressed: _busy
                      ? null
                      : () => _playOnce(
                          _assetPattern,
                          'Asset transient',
                          expectedSeconds: 1,
                        ),
                  child: const Text('Play asset AHAP'),
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  onPressed: _busy
                      ? null
                      : () => _playOnce(
                          _eventsPattern,
                          'Events pattern',
                          expectedSeconds: _eventsPatternDurationSec,
                        ),
                  child: const Text('Play events pattern'),
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  onPressed: _busy ? null : _playContinuous,
                  child: const Text('Play continuous (events)'),
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  onPressed: _busy ? null : _setIntensity,
                  child: const Text('Play with intensity 0.9'),
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  onPressed: _stopContinuous,
                  child: const Text('Stop continuous'),
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  onPressed: _busy
                      ? null
                      : () => _playOnce(
                          _inlinePattern,
                          'Inline AHAP',
                          expectedSeconds: 1,
                        ),
                  child: const Text('Play inline AHAP'),
                ),
                const Spacer(),
                const Text(
                  'Requires real iOS/macOS hardware with Core Haptics. '
                  'Add ios/Package.swift as a SwiftPM dependency to the host app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _inlineAhap = '''
{
  "Version":1,
  "Pattern":[
    {
      "Event":{
        "EventType":"HapticTransient",
        "Time":0,
        "EventParameters":[
          {"ParameterID":"HapticIntensity","ParameterValue":0.9},
          {"ParameterID":"HapticSharpness","ParameterValue":0.5}
        ]
      }
    }
  ]
}
''';
