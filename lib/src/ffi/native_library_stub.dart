import 'dart:ffi';

/// Stub implementation for web/WASM platforms.
///
/// Core Haptics requires native iOS/macOS APIs and is not available on web.
DynamicLibrary loadCoreHapticsLibrary() {
  throw UnsupportedError(
    'Core Haptics is only available on iOS and macOS. '
    'This package cannot load native libraries on web/WASM.',
  );
}
