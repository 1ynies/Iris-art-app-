import 'package:flutter/material.dart';
import '../widgets/iris_placeholder.dart';

class Case5View extends StatelessWidget {
  final String effect;
  final List<String> images;
  const Case5View({super.key, required this.effect, required this.images});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 700,
      height: 450,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Top Row (2)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              IrisPlaceholder(size: 100),
              SizedBox(width: 40),
              IrisPlaceholder(size: 100),
            ],
          ),
          const SizedBox(height: 20),
          const Text("FREE SPACE", style: TextStyle(color: Colors.white24)),
          const SizedBox(height: 20),
          // Bottom Row (3)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              IrisPlaceholder(size: 100),
              SizedBox(width: 40),
              IrisPlaceholder(size: 100),
              SizedBox(width: 40),
              IrisPlaceholder(size: 100),
            ],
          ),
        ],
      ),
    );
  }
}