import CoreHaptics
import Foundation

public typealias CHFFIEngineCallback = @convention(c) (Int32, UnsafePointer<CChar>?, UnsafeMutableRawPointer?) -> Void

private let notSupportedCode: Int32 = 1
private let engineCode: Int32 = 2
private let invalidHandleCode: Int32 = 3
private let invalidArgumentCode: Int32 = 4
private let patternErrorCode: Int32 = 5
private let playerErrorCode: Int32 = 6
private let ioErrorCode: Int32 = 7
private let decodeErrorCode: Int32 = 8
private let runtimeErrorCode: Int32 = 9
private let unknownErrorCode: Int32 = 255

private let eventStopped: Int32 = 1
private let eventReset: Int32 = 2
private let eventInterrupted: Int32 = 3
private let eventRestarted: Int32 = 4

private func setMessage(_ message: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?, _ text: String) {
    guard let message = message else { return }
    message.pointee = strdup(text)
}

private func supportsHaptics() -> Bool {
    CHHapticEngine.capabilitiesForHardware().supportsHaptics
}

private final class EngineBox {
    let engine: CHHapticEngine
    let queue: DispatchQueue
    let callback: CHFFIEngineCallback?
    let context: UnsafeMutableRawPointer?
    var callbacksEnabled: Bool = true

    init(engine: CHHapticEngine, callback: CHFFIEngineCallback?, context: UnsafeMutableRawPointer?) {
        self.engine = engine
        self.callback = callback
        self.context = context
        self.queue = DispatchQueue(label: "core.haptics.ffi.engine.\(UUID().uuidString)")
    }
}

private final class PatternBox {
    let pattern: CHHapticPattern

    init(pattern: CHHapticPattern) {
        self.pattern = pattern
    }
}

private final class PlayerBox {
    let player: CHHapticAdvancedPatternPlayer

    init(player: CHHapticAdvancedPatternPlayer) {
        self.player = player
    }
}

private func toHandle<T: AnyObject>(_ value: T) -> UnsafeMutableRawPointer {
    UnsafeMutableRawPointer(Unmanaged.passRetained(value).toOpaque())
}

private func fromHandle<T: AnyObject>(_ handle: UnsafeMutableRawPointer?) -> T? {
    guard let handle else { return nil }
    return Unmanaged<T>.fromOpaque(handle).takeUnretainedValue()
}

private func releaseHandle(_ handle: UnsafeMutableRawPointer?) {
    guard let handle else { return }
    Unmanaged<AnyObject>.fromOpaque(handle).release()
}

private func mapError(_ error: Error, message: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?) -> Int32 {
    if let err = error as? CHHapticError {
        switch err.code {
        case .engineNotRunning, .engineStartTimeout, .serverInitFailed:
            setMessage(message, err.localizedDescription)
            return engineCode
        case .notSupported:
            setMessage(message, err.localizedDescription)
            return notSupportedCode
        default:
            setMessage(message, err.localizedDescription)
            return runtimeErrorCode
        }
    }
    setMessage(message, error.localizedDescription)
    return unknownErrorCode
}

@_cdecl("chffi_string_free")
public func chffi_string_free(_ message: UnsafePointer<CChar>?) -> Int32 {
    guard let message else { return 0 }
    free(UnsafeMutablePointer(mutating: message))
    return 0
}

@_cdecl("chffi_engine_create")
public func chffi_engine_create(
    _ outHandle: UnsafeMutablePointer<UnsafeMutableRawPointer?>?,
    _ callback: CHFFIEngineCallback?,
    _ context: UnsafeMutableRawPointer?,
    _ message: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32 {
    guard supportsHaptics() else {
        setMessage(message, "Haptics not supported on this device")
        return notSupportedCode
    }

    do {
        let engine = try CHHapticEngine()
        engine.isAutoShutdownEnabled = false
        let box = EngineBox(engine: engine, callback: callback, context: context)

        engine.resetHandler = { [weak engine] in
            guard box.callbacksEnabled, let callback = callback else { return }
            callback(eventReset, nil, context)
            if let engine = engine {
                try? engine.start()
                callback(eventRestarted, nil, context)
            }
        }

        engine.stoppedHandler = { reason in
            guard box.callbacksEnabled, let callback = callback else { return }
            switch reason {
            case .audioSessionInterrupt:
                callback(eventInterrupted, nil, context)
            default:
                callback(eventStopped, nil, context)
            }
        }

        outHandle?.pointee = toHandle(box)
        return 0
    } catch {
        return mapError(error, message: message)
    }
}

@_cdecl("chffi_engine_start")
public func chffi_engine_start(
    _ handle: UnsafeMutableRawPointer?,
    _ message: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32 {
    guard let box: EngineBox = fromHandle(handle) else { return invalidHandleCode }
    var startError: Int32 = 0
    box.queue.sync {
        do {
            try box.engine.start()
        } catch {
            startError = mapError(error, message: message)
        }
    }
    return startError
}

@_cdecl("chffi_engine_stop")
public func chffi_engine_stop(
    _ handle: UnsafeMutableRawPointer?,
    _ message: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32 {
    guard let box: EngineBox = fromHandle(handle) else { return invalidHandleCode }
    var stopError: Int32 = 0
    box.queue.sync {
        box.engine.stop(completionHandler: { _ in })
    }
    return stopError
}

@_cdecl("chffi_engine_release")
public func chffi_engine_release(_ handle: UnsafeMutableRawPointer?) {
    guard let box: EngineBox = fromHandle(handle) else {
        releaseHandle(handle as UnsafeMutableRawPointer?)
        return
    }
    box.callbacksEnabled = false
    box.engine.resetHandler = {}
    box.engine.stoppedHandler = { _ in }
    box.engine.stop(completionHandler: { _ in })
    releaseHandle(handle as UnsafeMutableRawPointer?)
}

private func makePattern(from data: Data) throws -> CHHapticPattern {
    let rawObject = try JSONSerialization.jsonObject(with: data, options: [])
    guard let dict = rawObject as? [String: Any] else {
        throw NSError(domain: "chffi", code: 1, userInfo: nil)
    }
    var keyed: [CHHapticPattern.Key: Any] = [:]
    for (k, v) in dict {
        let key = CHHapticPattern.Key(rawValue: k)
        keyed[key] = v
    }
    return try CHHapticPattern(dictionary: keyed)
}

@_cdecl("chffi_pattern_from_ahap_data")
public func chffi_pattern_from_ahap_data(
    _ bytes: UnsafePointer<UInt8>?,
    _ length: Int32,
    _ outPattern: UnsafeMutablePointer<UnsafeMutableRawPointer?>?,
    _ message: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32 {
    guard let bytes, length > 0 else {
        setMessage(message, "Invalid AHAP buffer")
        return invalidArgumentCode
    }
    do {
        let data = Data(bytes: bytes, count: Int(length))
        let pattern = try makePattern(from: data)
        outPattern?.pointee = toHandle(PatternBox(pattern: pattern))
        return 0
    } catch {
        return mapError(error, message: message)
    }
}

@_cdecl("chffi_pattern_from_ahap_file")
public func chffi_pattern_from_ahap_file(
    _ path: UnsafePointer<CChar>?,
    _ outPattern: UnsafeMutablePointer<UnsafeMutableRawPointer?>?,
    _ message: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32 {
    guard let path else {
        setMessage(message, "Path is null")
        return invalidArgumentCode
    }
    do {
        let url = URL(fileURLWithPath: String(cString: path))
        let data = try Data(contentsOf: url)
        let pattern = try makePattern(from: data)
        outPattern?.pointee = toHandle(PatternBox(pattern: pattern))
        return 0
    } catch {
        return mapError(error, message: message)
    }
}

@_cdecl("chffi_pattern_release")
public func chffi_pattern_release(_ handle: UnsafeMutableRawPointer?) {
    releaseHandle(handle as UnsafeMutableRawPointer?)
}

@_cdecl("chffi_player_create")
public func chffi_player_create(
    _ engineHandle: UnsafeMutableRawPointer?,
    _ patternHandle: UnsafeMutableRawPointer?,
    _ outPlayer: UnsafeMutablePointer<UnsafeMutableRawPointer?>?,
    _ message: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32 {
    guard let engineBox: EngineBox = fromHandle(engineHandle) else { return invalidHandleCode }
    guard let patternBox: PatternBox = fromHandle(patternHandle) else { return invalidHandleCode }
    var result: Int32 = 0
    engineBox.queue.sync {
        do {
            let player = try engineBox.engine.makeAdvancedPlayer(with: patternBox.pattern)
            outPlayer?.pointee = toHandle(PlayerBox(player: player))
        } catch {
            result = mapError(error, message: message)
        }
    }
    return result
}

@_cdecl("chffi_player_play")
public func chffi_player_play(
    _ playerHandle: UnsafeMutableRawPointer?,
    _ atTime: Double,
    _ message: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32 {
    guard let playerBox: PlayerBox = fromHandle(playerHandle) else { return invalidHandleCode }
    do {
        try playerBox.player.start(atTime: atTime)
        return 0
    } catch {
        return mapError(error, message: message)
    }
}

@_cdecl("chffi_player_stop")
public func chffi_player_stop(
    _ playerHandle: UnsafeMutableRawPointer?,
    _ atTime: Double,
    _ message: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32 {
    guard let playerBox: PlayerBox = fromHandle(playerHandle) else { return invalidHandleCode }
    do {
        try playerBox.player.stop(atTime: atTime)
        return 0
    } catch {
        return mapError(error, message: message)
    }
}

@_cdecl("chffi_player_set_loop")
public func chffi_player_set_loop(
    _ playerHandle: UnsafeMutableRawPointer?,
    _ enabled: Int32,
    _ loopStart: Double,
    _ loopEnd: Double,
    _ message: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32 {
    guard let playerBox: PlayerBox = fromHandle(playerHandle) else { return invalidHandleCode }
    // macOS Core Haptics does not expose loopStart/loopEnd on CHHapticAdvancedPatternPlayer.
    setMessage(message, "Loop configuration not supported on this platform")
    playerBox.player.loopEnabled = enabled != 0
    return notSupportedCode
}

private func toParameterId(_ parameterId: Int32) -> CHHapticDynamicParameter.ID? {
    switch parameterId {
    case 1: return CHHapticDynamicParameter.ID(rawValue: "HapticIntensity")
    case 2: return CHHapticDynamicParameter.ID(rawValue: "HapticSharpness")
    case 3: return CHHapticDynamicParameter.ID(rawValue: "AttackTime")
    case 4: return CHHapticDynamicParameter.ID(rawValue: "DecayTime")
    case 5: return CHHapticDynamicParameter.ID(rawValue: "ReleaseTime")
    case 6: return CHHapticDynamicParameter.ID(rawValue: "Sustained")
    case 7: return CHHapticDynamicParameter.ID(rawValue: "AudioVolume")
    case 8: return CHHapticDynamicParameter.ID(rawValue: "AudioPan")
    case 9: return CHHapticDynamicParameter.ID(rawValue: "AudioPitch")
    case 10: return CHHapticDynamicParameter.ID(rawValue: "AudioBrightness")
    default: return nil
    }
}

@_cdecl("chffi_player_send_parameter")
public func chffi_player_send_parameter(
    _ playerHandle: UnsafeMutableRawPointer?,
    _ parameterId: Int32,
    _ value: Double,
    _ atTime: Double,
    _ message: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32 {
    guard let playerBox: PlayerBox = fromHandle(playerHandle) else { return invalidHandleCode }
    guard let id = toParameterId(parameterId) else {
        setMessage(message, "Unsupported parameter id \(parameterId)")
        return invalidArgumentCode
    }
    do {
        let parameter = CHHapticDynamicParameter(parameterID: id, value: Float(value), relativeTime: 0)
        try playerBox.player.sendParameters([parameter], atTime: atTime)
        return 0
    } catch {
        return mapError(error, message: message)
    }
}

@_cdecl("chffi_player_release")
public func chffi_player_release(_ handle: UnsafeMutableRawPointer?) {
    releaseHandle(handle as UnsafeMutableRawPointer?)
}

@_cdecl("chffi_supports_haptics")
public func chffi_supports_haptics() -> Int32 {
    return CHHapticEngine.capabilitiesForHardware().supportsHaptics ? 1 : 0
}

#if canImport(UIKit)
import UIKit
#endif

@_cdecl("chffi_impact_light")
public func chffi_impact_light() {
    #if canImport(UIKit) && !os(tvOS)
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    #endif
}

@_cdecl("chffi_impact_medium")
public func chffi_impact_medium() {
    #if canImport(UIKit) && !os(tvOS)
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    #endif
}

@_cdecl("chffi_impact_heavy")
public func chffi_impact_heavy() {
    #if canImport(UIKit) && !os(tvOS)
    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    #endif
}

@_cdecl("chffi_impact_soft")
public func chffi_impact_soft() {
    #if canImport(UIKit) && !os(tvOS)
    if #available(iOS 13.0, *) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    #endif
}

@_cdecl("chffi_impact_rigid")
public func chffi_impact_rigid() {
    #if canImport(UIKit) && !os(tvOS)
    if #available(iOS 13.0, *) {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
    #endif
}

@_cdecl("chffi_notification_success")
public func chffi_notification_success() {
    #if canImport(UIKit) && !os(tvOS)
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    #endif
}

@_cdecl("chffi_notification_warning")
public func chffi_notification_warning() {
    #if canImport(UIKit) && !os(tvOS)
    UINotificationFeedbackGenerator().notificationOccurred(.warning)
    #endif
}

@_cdecl("chffi_notification_error")
public func chffi_notification_error() {
    #if canImport(UIKit) && !os(tvOS)
    UINotificationFeedbackGenerator().notificationOccurred(.error)
    #endif
}

@_cdecl("chffi_selection")
public func chffi_selection() {
    #if canImport(UIKit) && !os(tvOS)
    UISelectionFeedbackGenerator().selectionChanged()
    #endif
}

