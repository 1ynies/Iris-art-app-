// ignore_for_file: unused_element

/// Shared loader for iris_engine.dll on Windows. Uses only the filename
/// 'iris_engine.dll' so the OS looks in the executable directory (where
/// CMake POST_BUILD copies it), and never a full absolute path.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';

const String _dllName = 'iris_engine.dll';

/// On Windows, loads iris_engine.dll by name only so it is resolved from the
/// executable directory. Returns null on other platforms or on load failure.
DynamicLibrary? loadIrisEngine() {
  if (!Platform.isWindows) return null;

  try {
    // Filename only — Windows searches the executable directory first.
    return DynamicLibrary.open(_dllName);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Iris Engine: could not load $_dllName. Error: $e');
      if (e.toString().contains('126') ||
          e.toString().toLowerCase().contains('module could not be found')) {
        debugPrint(
          'Iris Engine: Ensure iris_engine.dll and OpenCV DLLs are copied next to the exe (see CMake POST_BUILD).',
        );
      }
    }
    return null;
  }
}
