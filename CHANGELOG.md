## 0.0.8

* Remove unused `dart:typed_data` import.

## 0.0.7

* Use stub on web/WASM, native implementation when `dart:io` is available.

## 0.0.6

* Cross-platform support.
  - On iOS/macOS: Uses native Core Haptics via FFI
  - On Android/Windows/Linux/Web: Falls back to Flutter's `HapticFeedback`
* Added `supportsAdvancedHaptics` property to check if full Core Haptics API is available.
* Advanced features (`HapticEngine.create()`, patterns, players) now throw `HapticsException(notSupported)` on non-Apple platforms with a helpful message.
* Updated documentation with platform support matrix.

## 0.0.5

* Update documentation with Swift Package Manager setup instructions.

## 0.0.4

* Remove `library core_haptics` directive.

## 0.0.3

* Static methods now auto-check `isSupported` and silently no-op on unsupported devices.
* No need to wrap one-liner calls in `isSupported` checks anymore.

## 0.0.2

* Improve documentation.

## 0.0.1

* Initial release with basic Core Haptics API.
