import 'package:flutter/material.dart';

class CirclingParams {
  final String inputPath;
  final String outputPath;
  final double outerRadiusVal;
  final double innerRadiusVal;
  final double ovalRatio;
  final Offset outerOffset;
  final Offset innerOffset;
  final Size viewSize;

  CirclingParams({
    required this.inputPath,
    required this.outputPath,
    required this.outerRadiusVal,
    required this.innerRadiusVal,
    required this.ovalRatio,
    required this.outerOffset,
    required this.innerOffset,
    required this.viewSize,
  });
}
