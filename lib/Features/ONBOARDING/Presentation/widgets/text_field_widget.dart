import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iris_designer/Core/Config/Theme.dart';

class TextFieldWidget extends StatelessWidget {
  final String label;
  final String prefixicon;
  final bool autofocus;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const TextFieldWidget({
    super.key,
    required this.label,
    required this.prefixicon,
    required this.autofocus,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        //-- Validator --
        validator: validator,
        // -- Controller  --
        controller: controller,
        autofocus: autofocus,
        maxLines: 1,
        cursorColor: Colors.black87,
        // Apply Manrope font styling
        style: GoogleFonts.poppins(
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        decoration: InputDecoration(
          // --- Prefix Icon ---
          prefixIcon: Padding(
            padding: EdgeInsets.all(10),

            child: SvgPicture.asset(
              prefixicon,
              width: 20,
              height: 20,
              color: AppColors.textGrey,
            ),
          ),

          // --- Focused Border ---
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryBlue),
          ),

          hintText: label,
          hintStyle: const TextStyle(color: AppColors.textGrey),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),

          // --- ERROR BORDER (Red when invalid) ---
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),

          // --- FOCUSED ERROR BORDER (Red when invalid and clicked) ---
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Colors.red, width: 1.5),
          ),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
