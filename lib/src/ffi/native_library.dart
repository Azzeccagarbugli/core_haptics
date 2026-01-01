// Use stub on web/WASM, native implementation when dart:io is available.
export 'native_library_stub.dart'
    if (dart.library.io) 'native_library_native.dart';
