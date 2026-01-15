import 'package:flutter/material.dart';
import '../widgets/iris_placeholder.dart';

class Case1View extends StatelessWidget {
  final String effect;
  final List<String> images;
  const Case1View({super.key, required this.effect,required this.images});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      height: 600,
      decoration: BoxDecoration(
        color: Colors.black, // Light grey "Free Space"
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: IrisPlaceholder(
          size: 250,
          imagePath: images.isNotEmpty ? images[0] : null, // ✅ Pass image 0
        ),
      ),
    );
  }
}