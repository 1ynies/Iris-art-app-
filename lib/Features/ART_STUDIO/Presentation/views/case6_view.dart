import 'package:flutter/material.dart';
import '../widgets/iris_placeholder.dart';

class Case6View extends StatelessWidget {
  final String effect;
  final List<String> images;
  const Case6View({super.key, required this.effect, required this.images});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 700,
      height: 450,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dotted Border Overlay (Simulated)
          Positioned(
            top: 20, bottom: 20, left: 20, right: 20,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white12, width: 1, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Row 1
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  IrisPlaceholder(size: 110, label: "+"),
                  SizedBox(width: 20),
                  IrisPlaceholder(size: 110, label: "+"),
                  SizedBox(width: 20),
                  IrisPlaceholder(size: 110, label: "+"),
                ],
              ),
              const SizedBox(height: 20),
              // Row 2
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  IrisPlaceholder(size: 110, label: "+"),
                  SizedBox(width: 20),
                  IrisPlaceholder(size: 110, label: "+"),
                  SizedBox(width: 20),
                  IrisPlaceholder(size: 110, label: "+"),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}