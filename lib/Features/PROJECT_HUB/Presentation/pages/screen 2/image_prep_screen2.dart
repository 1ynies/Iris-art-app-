import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iris_designer/Core/Shared/Widgets/global_custom_navbar.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/pages/screen%202/views/image_editing_view.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/pages/screen%202/views/image_prep_view2.dart';

class ImagePrepScreen2 extends StatelessWidget {
  final ClientSession session; 
  final List<String> imageUrls;
  
  const ImagePrepScreen2({super.key, required this.session, required this.imageUrls,});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ 1. Match Main Background Color
      backgroundColor: const Color(0xFF181E28),
      
      // ✅ 2. Use Global Custom Navbar
      appBar: CustomNavBar(
        title: "Iris Editor Workspace",
        onArrowPressed: () {
          // Navigate back (or to specific route if needed)
          context.goNamed(
            'iris-editor', 
            extra: {
              'session': session,      // Passing session info back
              'imageUrls': imageUrls,  // Passing the images back
            },
          );
        },
        helpDialogNum: '4',
      ),
      
      // ✅ 3. Split Layout (Row)
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
            color: Colors.white.withOpacity(0.1), // Subtle divider for dark mode
          ),
          
          // --- RIGHT HALF: Main Workspace ---
          Expanded(
            flex: 1, // Gave more space to workspace (optional, change to 1 if you want 50/50)
            child:  MainWorkspaceView(session: session),
          ),
        ],
      ),
    );
  }
}