/// Stable error codes returned by the native Core Haptics bridge.
enum HapticsErrorCode {
  /// No error.
  ok(0),

  /// Device does not support Core Haptics.
  notSupported(1),

  /// Engine could not start or run.
  engine(2),

  /// Handle was invalid or already released.
  invalidHandle(3),

  /// A bad argument or pattern was provided.
  invalidArgument(4),

  /// Pattern creation failed.
  pattern(5),

  /// Player creation or control failed.
  player(6),

  /// File or IO issue (e.g., missing AHAP file).
  io(7),

  /// AHAP decode/encode failure.
  decode(8),

  /// Runtime playback error.
  runtime(9),

  /// Unknown or unmapped native error code.
  unknown(255);

  const HapticsErrorCode(this.code);

  /// Numeric code coming from the native layer.
  final int code;

  /// Map a native integer code to the Dart enum.
  static HapticsErrorCode fromNative(int code) {
    return HapticsErrorCode.values.firstWhere(
      (c) => c.code == code,
      orElse: () => HapticsErrorCode.unknown,
    );
  }
}

/// Exception thrown for Core Haptics failures.
class HapticsException implements Exception {
  /// Create a typed exception with an optional human-readable message.
  HapticsException(this.code, [this.message]);

  /// Categorized error code.
  final HapticsErrorCode code;

  /// Optional detail from the native layer.
  final String? message;

  @override
  String toString() => 'HapticsException($code): ${message ?? ''}';
}
