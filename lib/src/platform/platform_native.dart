import 'dart:io' show Platform;

/// Returns `true` if running on iOS or macOS (platforms with Core Haptics).
bool get isApplePlatform => Platform.isIOS || Platform.isMacOS;
