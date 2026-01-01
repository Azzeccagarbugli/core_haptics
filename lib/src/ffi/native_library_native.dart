import 'dart:ffi';
import 'dart:io';

/// Load the Core Haptics library.
DynamicLibrary loadCoreHapticsLibrary() {
  /// Load the Core Haptics library from the process.
  if (Platform.isIOS || Platform.isMacOS) {
    // Symbols are linked directly from the SwiftPM-built dynamic library.
    return DynamicLibrary.process();
  }
  throw UnsupportedError('Core Haptics is only available on iOS or macOS.');
}
