// Use stub on web/WASM, native FFI implementation when dart:ffi is available.
export 'haptics_stub.dart' if (dart.library.ffi) 'haptics_io.dart';
