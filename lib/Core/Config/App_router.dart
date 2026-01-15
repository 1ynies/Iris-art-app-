import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // ✅ Corrected Import name if needed
import 'package:iris_designer/Features/ART_STUDIO/Presentation/pages/iris_studio_screen.dart';
import 'package:iris_designer/Features/EDITOR/Domain/usecases/save_image_progress_usecase.dart';
import 'package:iris_designer/Features/EDITOR/Presentation/bloc/editor_bloc.dart';
import 'package:iris_designer/Features/EDITOR/Presentation/bloc/editor_event.dart';
import 'package:iris_designer/Features/EDITOR/Presentation/pages/iris_editing_screen.dart';
import 'package:iris_designer/Features/ONBOARDING/Presentation/pages/splash_screen.dart';
import 'package:iris_designer/Features/ONBOARDING/Presentation/pages/client_intake_screen.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/pages/screen%201/image_prep_screen1.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/pages/screen%202/image_prep_screen2.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    
    // 🛡️🛡️🛡️ REDIRECT LOGIC 🛡️🛡️🛡️
    redirect: (context, state) {
      final String location = state.uri.toString();

      // Fix: Allow both ClientSession AND Map to access image-prep
      if (location == '/image-prep') {
        final hasValidData = state.extra is ClientSession || state.extra is Map;
        
        if (!hasValidData) {
          return '/intake'; // Only redirect if data is truly missing
        }
      }
      return null;
    },

    routes: [
      // === SPLASH ===
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // === CLIENT INTAKE ===
      GoRoute(
        path: '/intake',
        name: 'client-intake',
        builder: (context, state) {
          final sessionToEdit = state.extra as ClientSession?;
          return ClientIntakeScreen(existingSession: sessionToEdit);
        },
      ),

      // === IMAGE PREP 1 (HUB) ===
      GoRoute(
        path: '/image-prep',
        name: 'image-prep',
        builder: (context, state) {
          ClientSession session;
          List<String>? returnedImages;

          // 1. If coming from Intake (Just Session)
          if (state.extra is ClientSession) {
            session = state.extra as ClientSession;
          } 
          // 2. ✅ If coming BACK from Editor (Map: Session + Images)
          else if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            session = map['session'] as ClientSession;
            // Extract images safely
            if (map['returnedImages'] != null) {
               returnedImages = (map['returnedImages'] as List).map((e) => e.toString()).toList();
            }
          } 
          // 3. Fallback (Prevents Crash)
          else {
            session = ClientSession(
              id: '0', 
              clientName: 'Unknown', 
              email: '', 
              country: '',
              createdAt: DateTime.now(), // ✅ Fixed: Added required field
            );
          }

          return ImagePrepScreen1(
            session: session,
            returnedImages: returnedImages,
          );
        },
      ),

      // === IMAGE PREP 2 (WORKSPACE) ===
      GoRoute(
        path: '/image-prep-2',
        name: 'image-prep-2',
        builder: (context, state) {
          ClientSession session;
          List<String> imageUrls = [];

          if (state.extra is Map<String, dynamic>) {
             final map = state.extra as Map<String, dynamic>;
             session = map['session'] as ClientSession;
             if (map['imageUrls'] != null) {
               imageUrls = (map['imageUrls'] as List).map((e) => e.toString()).toList();
             }
          } else if (state.extra is ClientSession) {
            session = state.extra as ClientSession;
          } else {
            session = ClientSession(
              id: '0', 
              clientName: 'Unknown', 
              email: '', 
              country: '',
              createdAt: DateTime.now(), // ✅ Fixed: Added required field
            );
          }

          return ImagePrepScreen2(
            session: session, 
            imageUrls: imageUrls, 
          );
        },
      ),

      // === EDITOR ===
      GoRoute(
        path: '/editor',
        name: 'iris-editor',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          
          return BlocProvider(
            create: (context) => EditorBloc(
              saveProgressUseCase: SaveImageProgressUseCase(),
            )..add(LoadEditorSession(extras['imageUrls'])),
            
            child: IrisEditingScreen(
              imageUrls: extras['imageUrls'],
              session: extras['session'],
            ),
          );
        },
      ),

      // ✅ === ART STUDIO ===
      GoRoute(
        path: '/art-studio',
        name: 'art-studio',
        builder: (context, state) {
          // Expecting a Map with both 'imageUrls' and 'session'
          final extras = state.extra as Map<String, dynamic>;
          
          return ArtStudioScreen(
            irisImages: extras['imageUrls'] as List<String>,
            session: extras['session'] as ClientSession, // ✅ Pass Session
          );
        },
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text("Oups ! Page introuvable."))),
  );
}