import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iris_designer/Features/EDITOR/Domain/entities/iris_image.dart';

class FlashCorrectionView extends StatefulWidget {
  final IrisImage activeImage;
  final Function(List<Map<String, double>>) onBrushStroke;

  const FlashCorrectionView({super.key, required this.activeImage, required this.onBrushStroke});

  @override
  State<FlashCorrectionView> createState() => _FlashCorrectionViewState();
}

class _FlashCorrectionViewState extends State<FlashCorrectionView> {
  List<Offset> _currentStroke = [];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        onPanUpdate: (d) => setState(() => _currentStroke.add(d.localPosition)),
        behavior: HitTestBehavior.opaque,
        onPanEnd: (d) {
          // Normalize points
          final points = _currentStroke.map((p) => {
            'x': p.dx / constraints.maxWidth,
            'y': p.dy / constraints.maxHeight
          }).toList();
          widget.onBrushStroke(points);
          setState(() => _currentStroke.clear()); // Clear visual after send
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(widget.activeImage.imagePath),
              fit: widget.activeImage.isCirclingDone || widget.activeImage.imagePath.contains('edited_')
                  ? BoxFit.cover
                  : BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
            CustomPaint(painter: _BrushPainter(_currentStroke)),
          ],
        ),
      );
    });
  }
}

class _BrushPainter extends CustomPainter {
  final List<Offset> points;
  _BrushPainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.red..strokeWidth = 10..strokeCap = StrokeCap.round;
    for(int i=0; i<points.length-1; i++) canvas.drawLine(points[i], points[i+1], p);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}