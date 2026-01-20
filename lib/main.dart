
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ✅ 1. Keep this core import
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; 

// ✅ 2. ADD THESE MISSING IMPORTS (This fixes the red lines)
// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview_windows/flutter_inappwebview_windows.dart'; 
// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview_macos/flutter_inappwebview_macos.dart';

import 'package:iris_designer/Core/Config/App_router.dart';
import 'package:iris_designer/Core/Config/dependecy_injection.dart' as di;
import 'package:iris_designer/Core/Config/hive_init.dart';
import 'package:iris_designer/Core/Services/hive_service.dart';
import 'package:iris_designer/Features/ONBOARDING/Presentation/bloc/onboarding_bloc.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/bloc/project_hub_bloc.dart';

void main(List<String> args) async {

  // 1. ✅ Initialize Hive
  
  // ✅ Initialize Hive
  await HiveService.init();
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // 2. ✅ MANUAL REGISTRATION (The Fix)
  // This forces Flutter to recognize the WebView engine on Linux
  
  await di.init();
  runApp(const MyApp());
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