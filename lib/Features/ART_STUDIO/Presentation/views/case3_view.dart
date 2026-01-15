import 'package:flutter/material.dart';
import '../widgets/iris_placeholder.dart';

class Case3View extends StatelessWidget {
  final String effect;
  final List<String> images;
  const Case3View({super.key, required this.effect, required this.images});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      height: 500,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Top
          const IrisPlaceholder(size: 120, label: "+"),
          const SizedBox(height: 30),
          // Bottom Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              IrisPlaceholder(size: 120, label: "+"),
              SizedBox(width: 30),
              IrisPlaceholder(size: 120, label: "+"),
            ],
          ),
        ],
      ),
    );
  }
}