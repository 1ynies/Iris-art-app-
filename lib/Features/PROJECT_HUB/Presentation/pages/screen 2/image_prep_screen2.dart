import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iris_designer/Core/Services/hive_service.dart';
import 'package:iris_designer/Core/Shared/Widgets/global_custom_navbar.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/pages/screen%202/views/image_editing_view.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/pages/screen%202/views/image_prep_view2.dart';

class ImagePrepScreen2 extends StatelessWidget {
  final ClientSession session;
  /// Edited images only (from editor or session.generatedArt in Hive).
  final List<String> imageUrls;

  const ImagePrepScreen2({super.key, required this.session, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181E28),
      appBar: CustomNavBar(
        title: "Iris Editor Workspace",
        onArrowPressed: () async {
          await HiveService.updateSessionGeneratedArt(session.id, imageUrls);
          if (!context.mounted) return;
          context.goNamed(
            'iris-editor',
            extra: {
              'session': session,
              'imageUrls': imageUrls,
            },
          );
        },
        helpDialogNum: '4',
      ),
      
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- LEFT HALF: Gallery / Sidebar ---
          Expanded(
            flex: 1, 
            child: ImagePrepView2(
              session: session, 
              preloadedImages: imageUrls, 
            ),
          ),
          
          // --- DIVIDER LINE ---
          Container(
            width: 1, 
            color: Colors.white.withOpacity(0.1), 
          ),
          
          // --- RIGHT HALF: Main Workspace ---
          Expanded(
            flex: 1, 
            child:  MainWorkspaceView(session: session),
          ),
        ],
      ),
    );
  }
}