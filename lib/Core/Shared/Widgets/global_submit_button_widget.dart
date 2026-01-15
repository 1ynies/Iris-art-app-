import 'package:flutter/material.dart';
import 'package:flutter_gap/flutter_gap.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iris_designer/Core/Config/Theme.dart';

// ignore: must_be_immutable
class GlobalSubmitButtonWidget extends StatelessWidget {
  late String icon;
  late Color svgColor;
  late VoidCallback onPressed;
  late String title;
  GlobalSubmitButtonWidget( {
    super.key,
    required this.onPressed,
    required this.title,
    required this.icon,
    required this.svgColor 
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // width: 100 ,
      height: 50,
      child: Container(
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.textWhite, // Text color
            elevation:
                0.5, // Disable default elevation to control shadow manually
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                10,
              ), // Matches the decoration radius
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          ),
          child: Row(
            mainAxisAlignment:  MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Gap(8), 
              SvgPicture.asset(icon, color: svgColor, height: 20 , width: 20 ),
            ],
          ),
        ),
      ),
    );
  }
}
