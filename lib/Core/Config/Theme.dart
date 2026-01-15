

import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  static const Color backgroundDark = Color(0xFF121820);
  static const Color cardBackground = Color(0xFF1E2732);
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFFA0AAB8);
  static const Color inputBorder = Color(0xFF374151);
}



class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    color: AppColors.textWhite,
    fontSize: 40,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  static const TextStyle heading2 = TextStyle(
    color: AppColors.textWhite,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle bodyText = TextStyle(
    color: AppColors.textGrey,
    fontSize: 14,
    height: 1.5,
  );
  static const TextStyle labelText = TextStyle(
    color: AppColors.textGrey,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle buttonText = TextStyle(
    color: AppColors.textWhite,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
}