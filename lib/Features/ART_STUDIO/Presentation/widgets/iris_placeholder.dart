import 'dart:io';

import 'package:flutter/material.dart';

class IrisPlaceholder extends StatelessWidget {
  final double size;
  final String? label;
  final Color color;
  final String? imagePath;

  const IrisPlaceholder({
    super.key,
    this.size = 100,
    this.label,
    this.imagePath,
    this.color = const Color(0xFF1E293B), // Default dark grey
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.3),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipOval(
        child: imagePath != null
            ? Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
                width: size,
                height: size,
              )
            : Center(
                child: Icon(Icons.add, color: Colors.white24, size: size * 0.3),
              ),
      ),
    );
  }
}