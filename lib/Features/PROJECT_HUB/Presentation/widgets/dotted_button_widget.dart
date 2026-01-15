// !Unused file









// import 'package:dotted_border/dotted_border.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_gap/flutter_gap.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:google_fonts/google_fonts.dart';

// class DottedButtonWidget extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: () {
//         // * todo : implement the file picker
//       },
//       child: DottedBorder(
//         color: Color(0xFF687890), //color of dotted/dash line
//         strokeWidth: 2, //thickness of dash/dots
//         dashPattern: const [
//           8,
//           4,
//         ], //dash patterns, 8 is dash width, 4 is space width
//         borderType: BorderType.RRect, //RRect for rounded corner
//         radius: const Radius.circular(12), //radius for rounded corner
//         child: SizedBox(
//           height: 100,
//           width: double.infinity,

//           // color: Colors.blue.withOpacity(0.1),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 width: 48,
//                 height: 48,
//                 decoration: const BoxDecoration(
//                   color: Color(0xFF2A3441), // Lighter grey-blue circle
//                   shape: BoxShape.circle,
//                 ),
//                 // Padding inside ensures the SVG isn't too big
//                 padding: const EdgeInsets.all(12),
//                 child: SvgPicture.asset(
//                   "assets/Icons/arrow_up_tray.svg",
//                   // Using colorFilter is the modern way to color SVGs
//                   colorFilter: const ColorFilter.mode(
//                     Color(0xFF94A3B8), // Light grey icon color
//                     BlendMode.srcIn,
//                   ),
//                 ),
//               ),
//               const Gap(8),
//               Text(
//                 'Open image picker',
//                 style: GoogleFonts.poppins(textStyle: TextStyle(fontSize: 15)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
