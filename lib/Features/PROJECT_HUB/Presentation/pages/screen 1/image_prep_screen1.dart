import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iris_designer/Core/Shared/Widgets/global_custom_navbar.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/pages/screen%201/views/image_prep_view1.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/pages/screen%201/views/instruction_view.dart';

class ImagePrepScreen1 extends StatelessWidget {
  final ClientSession session; 
  final List<String>? returnedImages;
  
  const ImagePrepScreen1({super.key, required this.session , this.returnedImages});
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Main background color from the design
      backgroundColor: const Color(0xFF181E28),
      appBar:  CustomNavBar(
        title: "Iris Designer",
        
        onArrowPressed: () {
          context.goNamed(
            'client-intake',
            extra: session, 
          );
        },
        helpDialogNum: '2',
      ),
      body: Row(
        children: [
          // Left Half: Image Prep View
           Expanded(
            flex: 1, // Takes up 60% of the space
            child: ImagePrepView(session: session , returnedImages: returnedImages,),
          ),
          // A subtle vertical divider
          Container(
            width: 1, // Thickness of the line
            height: double.infinity, // Full height
            color: Colors.white.withOpacity(0.1), // Subtle color for dark mode
          ),
          // Right Half: Instruction View
          Expanded(
            flex: 1,
            // ✅ Pass the client name from the session
            child: InstructionView(
              clientName: session.clientName,
            ),
          ),
        ],
      ),
    );
  }
}
