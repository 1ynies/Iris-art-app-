import 'package:flutter/material.dart';
import '../widgets/iris_placeholder.dart';

class Case4View extends StatelessWidget {
  final String effect;
  final List<String> images;
  const Case4View({super.key, required this.effect, required this.images});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      height: 450,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Row 1
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              IrisPlaceholder(size: 110, label: "+", color: Colors.blue),
              SizedBox(width: 30),
              IrisPlaceholder(size: 110, label: "+", color: Colors.green),
            ],
          ),
          const SizedBox(height: 30),
          // Row 2
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              IrisPlaceholder(size: 110, label: "+", color: Colors.red),
              SizedBox(width: 30),
              IrisPlaceholder(size: 110, label: "+", color: Colors.purple),
            ],
          ),
          const SizedBox(height: 20),
          const Text("ART STUDIO", style: TextStyle(color: Colors.white12, letterSpacing: 3)),
        ],
      ),
    );
  }
}