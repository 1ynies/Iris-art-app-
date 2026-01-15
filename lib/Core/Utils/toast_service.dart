import 'package:flutter/material.dart';
import 'package:flutter_gap/flutter_gap.dart';

class ToastService {
  
  static void showSuccess(BuildContext context, {
    required String title,
    required String message,
  }) {
    _showToast(
      context,
      title: title,
      message: message,
      icon: Icons.check_circle,
      iconColor: const Color(0xFF2ECC71),
      backgroundColor: const Color(0xFF181E28),
      borderColor: const Color(0xFF2ECC71).withOpacity(0.5),
    );
  }

  static void showError(BuildContext context, {
    required String title,
    required String message,
  }) {
    _showToast(
      context,
      title: title,
      message: message,
      icon: Icons.error,
      iconColor: const Color(0xFFE74C3C),
      backgroundColor: const Color(0xFF181E28),
      borderColor: const Color(0xFFE74C3C).withOpacity(0.5),
    );
  }

  static void _showToast(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    // 1. Force Width to 500px (or screen width if on mobile)
    double screenWidth = MediaQuery.of(context).size.width;
    double toastWidth = 500.0; 

    // Safety check: If screen is smaller than 500px (e.g. mobile), fit to screen
    if (screenWidth < 532) { // 500 + 16px padding on each side
      toastWidth = screenWidth - 32;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // ✅ CRITICAL: We set a fixed width.
        // When 'width' is set, 'margin' MUST be null.
        width: toastWidth,
        margin: null, 
        
        behavior: SnackBarBehavior.floating, 
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                child: const Icon(Icons.close, color: Colors.grey, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}