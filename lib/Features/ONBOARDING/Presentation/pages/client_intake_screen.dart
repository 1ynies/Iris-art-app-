import 'package:flutter/material.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';
import 'package:iris_designer/Features/ONBOARDING/Presentation/pages/views/intake_screen_first_half.dart';
import 'package:iris_designer/Features/ONBOARDING/Presentation/pages/views/intake_screen_second_half.dart';





  class ClientIntakeScreen extends StatelessWidget {
    final ClientSession? existingSession;
  const ClientIntakeScreen({super.key, this.existingSession});

  @override
  Widget build(BuildContext context) {
    // Using LayoutBuilder to ensure it only displays side-by-side on larger screens.
    // For smaller screens, you might normally stack them, but based on the prompt's
    // deskop focus, we'll enforce the split row.
    return  Scaffold(
      body: Row(
        children: [
          // Left half takes 50% width
          Expanded(
            flex: 1,
            child: LeftPromotionalView(),
          ),
          Container(
            width: 1, // Thickness of the line
            height: double.infinity, // Full height
            color: Colors.white.withOpacity(0.1), // Subtle color for dark mode
          ),
          // Right half takes 50% width
          Expanded(
            flex: 1,
            child: RightIntakeFormView(existingSession: existingSession),
          ),
        ],
      ),
    );
  }
}