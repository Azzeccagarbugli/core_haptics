/// Stub implementation for web/WASM platforms.
///
/// Core Haptics requires native iOS/macOS APIs and is not available on web.
/// This file exists only to satisfy conditional imports - it should never
/// actually be used since the FFI layer is guarded by conditional imports
/// at a higher level.
Never loadCoreHapticsLibrary() {
  throw UnsupportedError(
    'Core Haptics is only available on iOS and macOS. '
    'This package cannot load native libraries on web/WASM.',
  );
}
