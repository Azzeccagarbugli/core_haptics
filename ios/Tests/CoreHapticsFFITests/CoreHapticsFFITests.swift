import CoreHaptics
import XCTest
@testable import CoreHapticsFFI

final class CoreHapticsFFITests: XCTestCase {
    private func skipIfUnsupported() throws {
        if !CHHapticEngine.capabilitiesForHardware().supportsHaptics {
            throw XCTSkip("Device does not support Core Haptics")
        }
    }

    func testEngineLifecycle() throws {
        try skipIfUnsupported()
        var handle: UnsafeMutableRawPointer?
        var message: UnsafeMutablePointer<CChar>?
        XCTAssertEqual(chffi_engine_create(&handle, nil, nil, &message), 0)
        XCTAssertNil(message)
        XCTAssertNotNil(handle)
        XCTAssertEqual(chffi_engine_start(handle, &message), 0)
        XCTAssertNil(message)
        XCTAssertEqual(chffi_engine_stop(handle, &message), 0)
        XCTAssertNil(message)
        chffi_engine_release(handle)
    }

    func testPatternAndPlayerLifecycle() throws {
        try skipIfUnsupported()
        let ahap = """
        {
          "Version":1,
          "Pattern":[
            {
              "Event":{
                "Time":0,
                "EventType":"HapticTransient",
                "EventParameters":[
                  {"ParameterID":"HapticIntensity","ParameterValue":0.6},
                  {"ParameterID":"HapticSharpness","ParameterValue":0.6}
                ]
              }
            }
          ]
        }
        """
        let data = try XCTUnwrap(ahap.data(using: .utf8))

        var engine: UnsafeMutableRawPointer?
        var pattern: UnsafeMutableRawPointer?
        var player: UnsafeMutableRawPointer?
        var message: UnsafeMutablePointer<CChar>?

        XCTAssertEqual(chffi_engine_create(&engine, nil, nil, &message), 0)
        XCTAssertNil(message)
        XCTAssertEqual(chffi_engine_start(engine, &message), 0)
        XCTAssertNil(message)

        data.withUnsafeBytes { buffer in
            let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self)
            let code = chffi_pattern_from_ahap_data(ptr, Int32(buffer.count), &pattern, &message)
            XCTAssertEqual(code, 0)
            XCTAssertNil(message)
        }

        XCTAssertNotNil(pattern)
        XCTAssertEqual(chffi_player_create(engine, pattern, &player, &message), 0)
        XCTAssertNil(message)
        XCTAssertNotNil(player)

        XCTAssertEqual(chffi_player_play(player, 0, &message), 0)
        XCTAssertNil(message)
        XCTAssertEqual(chffi_player_stop(player, 0, &message), 0)
        XCTAssertNil(message)

        chffi_player_release(player)
        chffi_pattern_release(pattern)
        chffi_engine_release(engine)
    }

    func testInvalidParameterId() throws {
        try skipIfUnsupported()
        let ahap = """
        { "Version":1, "Pattern":[{"Event":{"Time":0,"EventType":"HapticContinuous","EventDuration":1.0}}]}
        """
        let data = try XCTUnwrap(ahap.data(using: .utf8))

        var engine: UnsafeMutableRawPointer?
        var pattern: UnsafeMutableRawPointer?
        var player: UnsafeMutableRawPointer?
        var message: UnsafeMutablePointer<CChar>?

        XCTAssertEqual(chffi_engine_create(&engine, nil, nil, &message), 0)
        XCTAssertEqual(chffi_engine_start(engine, &message), 0)

        data.withUnsafeBytes { buffer in
            let ptr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self)
            XCTAssertEqual(chffi_pattern_from_ahap_data(ptr, Int32(buffer.count), &pattern, &message), 0)
        }

        XCTAssertEqual(chffi_player_create(engine, pattern, &player, &message), 0)
        let invalidCode = chffi_player_send_parameter(player, 999, 1.0, 0, &message)
        XCTAssertEqual(invalidCode, 4)
        XCTAssertNotNil(message)
        chffi_string_free(message)

        chffi_player_release(player)
        chffi_pattern_release(pattern)
        chffi_engine_release(engine)
    }
}

