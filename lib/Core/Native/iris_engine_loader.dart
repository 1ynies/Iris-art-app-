// ignore_for_file: unused_element

/// Shared loader for iris_engine.dll on Windows. Tries multiple paths so the DLL
/// is found whether run from IDE, "flutter run", or the built exe.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';

const String _dllName = 'iris_engine.dll';

/// Tries to load iris_engine.dll from several locations. Returns the first that
/// succeeds, or null. In debug mode, logs attempted paths and the last error.
DynamicLibrary? loadIrisEngine() {
  if (!Platform.isWindows) return null;

  final sep = Platform.pathSeparator;
  final cwd = Directory.current.path;
  Object? lastError;
  final tried = <String>[];

  /// Candidate paths in order of preference.
  String? exeDirPath;
  try {
    final exe = File(Platform.resolvedExecutable).absolute.path;
    exeDirPath = '${File(exe).parent.path}$sep$_dllName';
  } catch (_) {}
  final candidates = <String?>[
    // 1) Next to the running exe (absolute)
    exeDirPath,
    // 2) Cwd (e.g. project root when started via "flutter run")
    '$cwd$sep$_dllName',
    // 3) Standard Flutter Windows debug output
    '$cwd${sep}build${sep}windows${sep}x64${sep}runner${sep}Debug$sep$_dllName',
    // 4) Standard Flutter Windows release output
    '$cwd${sep}build${sep}windows${sep}x64${sep}runner${sep}Release$sep$_dllName',
    // 5) Legacy runner layout
    '$cwd${sep}build${sep}windows${sep}runner${sep}Debug$sep$_dllName',
    '$cwd${sep}build${sep}windows${sep}runner${sep}Release$sep$_dllName',
    // 6) Simple name (uses cwd and PATH)
    _dllName,
  ];
  final paths = candidates.whereType<String>().toList();

  for (final path in paths) {
    if (path.isEmpty) continue;
    try {
      tried.add(path);
      final lib = DynamicLibrary.open(path);
      if (kDebugMode && tried.length > 1) {
        debugPrint('Iris Engine: loaded from $path');
      }
      return lib;
    } catch (e) {
      lastError = e;
    }
  }

  if (kDebugMode) {
    debugPrint(
      'Iris Engine: could not load $_dllName. Tried: ${tried.join("; ")}. Last error: $lastError',
    );
    if (lastError.toString().contains('126') ||
        lastError.toString().toLowerCase().contains('module could not be found')) {
      debugPrint(
        'Iris Engine: To fix, run copy_vcpkg_dlls_to_build.cmd then run the app, '
        'or run via build_with_opencv.cmd / run_iris_designer.cmd',
      );
    }
  }
  return null;
}
