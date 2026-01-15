// // ✅ CORRECT: extends StatelessWidget
// import 'package:flutter/material.dart';
// import 'package:iris_designer/Core/Config/Theme.dart';

// class CustomLabeledTextField extends StatelessWidget {
//   final String label;
//   final String hintText;
//   final IconData prefixIcon;
//   final TextEditingController? controller;

//   const CustomLabeledTextField({
//     super.key,
//     required this.label,
//     required this.hintText,
//     required this.prefixIcon,
//     this.controller,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: AppTextStyles.labelText),
//         const SizedBox(height: 8),
//         TextField(
//           controller: controller,

//           style: const TextStyle(color: AppColors.textWhite),

//           decoration: InputDecoration(
//             filled: true,
//             fillColor: Colors.transparent,
//             hintText: hintText,

//             hintStyle: const TextStyle(color: AppColors.textGrey),
//             prefixIcon: Icon(prefixIcon, 
//             color: AppColors.textGrey, size: 20),

//             contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),

//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: const BorderSide(color: AppColors.inputBorder),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: const BorderSide(color: AppColors.primaryBlue),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }