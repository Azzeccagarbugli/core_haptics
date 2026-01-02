// Use stub on web/WASM, native FFI implementation when dart:ffi is available.
export 'haptic_service_stub.dart'
    if (dart.library.ffi) 'haptic_service_io.dart';
