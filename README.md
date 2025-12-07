# core_haptics

> 🎮 Bring Apple's Core Haptics to Flutter — rich, custom haptic feedback for iOS & macOS.

A type-safe, FFI-based Flutter plugin that gives you full access to Apple's Core Haptics framework. Create custom vibration patterns, play AHAP files, and deliver tactile experiences that feel native.

## ✨ What's inside

- **🎯 Complete Core Haptics wrapper** — engines, patterns, players, and dynamic parameters
- **📄 AHAP everywhere** — load from JSON strings, files, or Flutter assets  
- **🎨 Programmatic patterns** — build haptic sequences with `HapticEvent` (no JSON needed!)
- **🛡️ Memory-safe FFI** — automatic cleanup with finalizers, strongly-typed enums
- **🎛️ Live parameter control** — adjust intensity and sharpness during playback
- **🔄 Interruption handling** — callbacks for audio session changes and resets
- **🚫 Zero CocoaPods** — Swift Package Manager only, clean and modern


## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  core_haptics: ^0.1.0
```

Then run:
```bash
flutter pub get
```

---

## 🔧 Platform Setup

### iOS / macOS (Swift Package Manager)

Since this plugin uses SwiftPM instead of CocoaPods, you need to manually link the native module:

**Step 1:** Open your app in Xcode  
`example/ios/Runner.xcworkspace` (or `macos/Runner.xcworkspace`)

**Step 2:** Add the local Swift Package  
- File → Add Package Dependencies  
- Click "Add Local..." and navigate to the plugin's `ios/` folder  
- Select `Package.swift` and add it

**Step 3:** Link to your target  
- In your app target's **Frameworks and Libraries**, add `CoreHapticsFFI`
- Set to **Embed & Sign** (iOS) or **Do Not Embed** (macOS)

**Requirements:**  
- iOS 13.0+ or macOS 11.0+
- Physical device with haptic engine (iPhone 8+ or supported Mac)

> [!NOTE] 
>SwiftPM gives cleaner builds, better dependency management, and is Apple's recommended approach for modern Swift libraries.

## 🚀 Quick Start

### Basic haptic tap

```dart
import 'package:core_haptics/core_haptics.dart';

Future<void> playSimpleTap() async {
  // Create and start the engine
  final engine = await HapticEngine.create();
  await engine.start();

  // Load an AHAP pattern (JSON string)
  final pattern = await engine.loadPatternFromAhap('''
  {
    "Version": 1,
    "Pattern": [{
      "Event": {
        "EventType": "HapticTransient",
        "Time": 0,
        "EventParameters": [
          {"ParameterID": "HapticIntensity", "ParameterValue": 0.8},
          {"ParameterID": "HapticSharpness", "ParameterValue": 0.5}
        ]
      }
    }]
  }
  ''');

  // Play it
  final player = await engine.createPlayer(pattern);
  await player.play();
  
  // Cleanup
  await player.dispose();
  await pattern.dispose();
  await engine.dispose();
}
```

### Programmatic patterns (no JSON!)

```dart
final pattern = await engine.loadPatternFromEvents([
  // Sharp tap at start
  const HapticEvent(
    type: HapticEventType.transient,
    time: Duration.zero,
    intensity: 1.0,
    sharpness: 0.8,
  ),
  // Continuous rumble after 300ms
  const HapticEvent(
    type: HapticEventType.continuous,
    time: Duration(milliseconds: 300),
    duration: Duration(seconds: 2),
    intensity: 0.6,
    sharpness: 0.3,
  ),
]);
```

### Load from Flutter assets

```dart
// 1. Add AHAP file to pubspec.yaml assets
// 2. Load it:
final pattern = await engine.loadPatternFromAsset('assets/haptics/my_pattern.ahap');
```

### Handle interruptions

```dart
final engine = await HapticEngine.create(
  onEvent: (event, message) {
    switch (event) {
      case HapticEngineEvent.interrupted:
        print('⚠️ Haptics interrupted: $message');
        break;
      case HapticEngineEvent.restarted:
        print('✅ Haptics resumed');
        break;
      // ...
    }
  },
);
```

## 🎯 API Reference

### `HapticEngine`
Your main entry point. Manages the Core Haptics engine lifecycle.

```dart
// Create
final engine = await HapticEngine.create(onEvent: callback);

// Start/stop
await engine.start();
await engine.stop();

// Load patterns
final p1 = await engine.loadPatternFromAhap(jsonString);
final p2 = await engine.loadPatternFromFile(path);
final p3 = await engine.loadPatternFromAsset('assets/pattern.ahap');
final p4 = await engine.loadPatternFromEvents(eventList);

// Create players
final player = await engine.createPlayer(pattern);

// Cleanup
await engine.dispose();
```

### `HapticPlayer`
Controls playback of a haptic pattern.

```dart
await player.play(atTime: 0);
await player.stop(atTime: 0);

// Looping (not available on all platforms)
await player.setLoop(enabled: true, loopStart: 0, loopEnd: 2.0);

// Dynamic parameter updates (during playback)
await player.setParameter(HapticParameterId.hapticIntensity, 0.9, atTime: 0);

await player.dispose();
```

### `HapticEvent`
Programmatically define haptic events.

```dart
const HapticEvent({
  required HapticEventType type,      // transient or continuous
  Duration time = Duration.zero,      // when to fire (relative to pattern start)
  Duration? duration,                 // required for continuous events
  double? intensity,                  // 0.0 to 1.0
  double? sharpness,                  // 0.0 to 1.0
});
```

### Error Handling

All errors throw `HapticsException`:

```dart
try {
  await engine.start();
} on HapticsException catch (e) {
  print('Error: ${e.code} - ${e.message}');
  // e.code is a HapticsErrorCode enum
}
```

**Error codes:**

| Code | Description |
|------|-------------|
| `notSupported` | Device doesn't support haptics |
| `engine` | Engine failed to start |
| `invalidArgument` | Bad pattern or parameter |
| `decode` | Invalid AHAP JSON |
| `io` | File not found |
| `runtime` | Playback issue |

---

## 🧪 Testing

**Dart unit tests:**  
```bash
flutter test
```
Uses mocked FFI bridge for ~90% API coverage.

**Swift native tests:**  
```bash
cd ios && swift test
```

Tests the Core Haptics bridge _(skips on devices without haptics)_.

## 🐛 Troubleshooting

### "Cannot find symbol 'chffi_engine_create'"
The SwiftPM package isn't linked. Go back to [Platform Setup](#-platform-setup) and ensure `CoreHapticsFFI` is added to your app target's frameworks.

### "Device does not support haptics"
Core Haptics requires an iPhone 8+ or newer Mac with Taptic Engine. Simulators don't support haptics.

### "HapticsException: runtime (-4820)"
Tried to send a parameter update to a player that isn't actively playing. Ensure the pattern is playing before calling `setParameter`.

## 📚 Learn More

- [Apple Core Haptics Documentation](https://developer.apple.com/documentation/corehaptics/)
- [AHAP File Format](https://developer.apple.com/documentation/corehaptics/representing_haptic_patterns_in_ahap_files)
- [Core Haptics WWDC Sessions](https://developer.apple.com/videos/play/wwdc2019/520/)

## 📄 License

See [LICENSE](LICENSE) for details.

## 🙌 Contributing

Issues and PRs welcome! This plugin maintains a 1:1 mapping with Core Haptics APIs, so contributions should align with Apple's framework design.
