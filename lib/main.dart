import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: depend_on_referenced_packages, unused_import
import 'package:flutter_inappwebview_windows/flutter_inappwebview_windows.dart'; // plugin registration

import 'package:iris_designer/Core/Config/App_router.dart';
import 'package:iris_designer/Core/Config/dependecy_injection.dart' as di;
import 'package:iris_designer/Core/Services/hive_service.dart';
import 'package:iris_designer/Features/ONBOARDING/Presentation/bloc/onboarding_bloc.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/bloc/project_hub_bloc.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // This app is Windows-only (Iris Engine, OpenCV, native tooling).
  if (!Platform.isWindows) {
    runApp(const _WindowsOnlyApp());
    return;
  }

  await HiveService.init();
  await di.init();
  runApp(const MyApp());
}

/// Shown when run on a non-Windows OS.
class _WindowsOnlyApp extends StatelessWidget {
  const _WindowsOnlyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iris Designer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF121820),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.desktop_windows, size: 64, color: Colors.blue.shade300),
                const SizedBox(height: 24),
                Text(
                  'Iris Designer runs on Windows only',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'This app uses the Iris Engine native DLL and OpenCV on Windows.\nLinux and macOS are not supported.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Wrap MaterialApp with MultiBlocProvider
    return MultiBlocProvider(
      providers: [
        // Provider for Onboarding Feature
        BlocProvider<OnboardingBloc>(
          create: (_) => di.sl<OnboardingBloc>(),
        ),
        
        // Provider for Project Hub Feature (if you want it global)
        BlocProvider<ProjectHubBloc>(
          create: (context) => di.sl<ProjectHubBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Iris Art App',
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121820),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF1E88E5),
            secondary: Color(0xFF1E2732),
          ),
          textTheme: Typography.material2018().white.apply(fontFamily: 'Roboto'),
        ),
      ),
    );
  }
}