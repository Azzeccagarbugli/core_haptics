import 'dart:typed_data';

/// Engine lifecycle events surfaced from Core Haptics.
enum HapticEngineEvent {
  /// Engine stopped.
  stopped,

  /// Engine reset.
  reset,

  /// Engine interrupted.
  interrupted,

  /// Engine restarted.
  restarted,
}

/// Event type: one-shot tap or continuous haptic.
enum HapticEventType {
  /// Transient haptic (one-shot tap).
  transient,

  /// Continuous haptic (sustained vibration).
  continuous,
}

/// Supported dynamic parameter identifiers.
enum HapticParameterId {
  /// Haptic intensity (0.0-1.0).
  hapticIntensity(1),

  /// Haptic sharpness (0.0-1.0).
  hapticSharpness(2),

  /// Attack time (seconds).
  attackTime(3),

  /// Decay time (seconds).
  decayTime(4),

  /// Release time (seconds).
  releaseTime(5),

  /// Sustained haptic (sustained vibration).
  sustained(6),

  /// Audio volume (0.0-1.0).
  audioVolume(7),

  /// Audio pan (0.0-1.0).
  audioPan(8),

  /// Audio pitch (0.0-1.0).
  audioPitch(9),

  /// Audio brightness (0.0-1.0).
  audioBrightness(10);

  const HapticParameterId(this.id);

  /// Native parameter identifier.
  final int id;
}

/// Raw AHAP data wrapper.
class AhapPattern {
  /// Create a wrapper from raw AHAP bytes (UTF-8 JSON).
  AhapPattern(this.bytes);

  /// Create a wrapper from an AHAP JSON string.
  factory AhapPattern.fromString(String ahap) {
    return AhapPattern(Uint8List.fromList(ahap.codeUnits));
  }

  /// Underlying AHAP bytes.
  final Uint8List bytes;
}

/// A single haptic event (transient or continuous) used to build patterns.
class HapticEvent {
  /// Create a new haptic event.
  const HapticEvent({
    required this.type,
    this.time = Duration.zero,
    this.duration,
    this.intensity,
    this.sharpness,
  });

  /// Event type: transient tap or continuous haptic.
  final HapticEventType type;

  /// Start time relative to pattern start.
  final Duration time;

  /// Duration for continuous events; null/omitted for transients.
  final Duration? duration;

  /// Optional intensity (0.0-1.0); if null, system default is used.
  final double? intensity;

  /// Optional sharpness (0.0-1.0); if null, system default is used.
  final double? sharpness;

  /// Convert to AHAP event map.
  Map<String, dynamic> toAhapEvent() {
    final durationSeconds =
        duration == null ? null : duration!.inMicroseconds / 1e6;
    final timeSeconds = time.inMicroseconds / 1e6;

    if (type == HapticEventType.continuous &&
        (durationSeconds == null || durationSeconds <= 0)) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Continuous events need duration > 0',
      );
    }
    final parameters = <Map<String, dynamic>>[];
    if (intensity != null) {
      parameters.add({
        'ParameterID': 'HapticIntensity',
        'ParameterValue': intensity,
      });
    }
    if (sharpness != null) {
      parameters.add({
        'ParameterID': 'HapticSharpness',
        'ParameterValue': sharpness,
      });
    }

    return {
      'Event': {
        'EventType': type == HapticEventType.transient
            ? 'HapticTransient'
            : 'HapticContinuous',
        'Time': timeSeconds,
        if (durationSeconds != null) 'EventDuration': durationSeconds,
        if (parameters.isNotEmpty) 'EventParameters': parameters,
      }
    };
  }
}
