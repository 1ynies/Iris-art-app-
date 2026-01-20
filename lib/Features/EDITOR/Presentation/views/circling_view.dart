import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_gap/flutter_gap.dart';
import 'package:iris_designer/Features/EDITOR/Domain/entities/iris_image.dart';

class CirclingView extends StatefulWidget {
  final IrisImage activeImage;
  final double outerRadius;
  final double innerRadius;
  final double ovalRatio;
  final Offset centerOffset;
  final Function(Offset delta) onPanUpdate;
  final Function(double newRadius) onRadiusChange; 

  const CirclingView({
    super.key,
    required this.activeImage,
    required this.outerRadius,
    required this.innerRadius,
    required this.ovalRatio,
    required this.centerOffset,
    required this.onPanUpdate,
    required this.onRadiusChange, 
  });

  @override
  State<CirclingView> createState() => _CirclingViewState();
}

class _CirclingViewState extends State<CirclingView> {
  ui.Image? _imageInfo;
  bool _isResizing = false; 

  @override
  void initState() {
    super.initState();
    _resolveImageDimensions();
  }

  @override
  void didUpdateWidget(covariant CirclingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeImage.imagePath != widget.activeImage.imagePath) {
      _resolveImageDimensions();
    }
  }

  void _resolveImageDimensions() {
    final ImageProvider provider = FileImage(File(widget.activeImage.imagePath));
    provider.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          if (mounted) {
            setState(() {
              _imageInfo = info.image;
            });
          }
        },
        onError: (exception, stackTrace) {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_imageInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double imgWidth = _imageInfo!.width.toDouble();
        final double imgHeight = _imageInfo!.height.toDouble();
        final double imgRatio = imgWidth / imgHeight;
        final double containerRatio = constraints.maxWidth / constraints.maxHeight;

        double displayedWidth;
        double displayedHeight;

        if (containerRatio > imgRatio) {
          displayedHeight = constraints.maxHeight;
          displayedWidth = displayedHeight * imgRatio;
        } else {
          displayedWidth = constraints.maxWidth;
          displayedHeight = displayedWidth / imgRatio;
        }

        final double dx = (constraints.maxWidth - displayedWidth) / 2;
        final double dy = (constraints.maxHeight - displayedHeight) / 2;
        final Rect imageRect = Rect.fromLTWH(dx, dy, displayedWidth, displayedHeight);

        final double baseRadius = imageRect.shortestSide / 2;
        final double pixelRadius = baseRadius * widget.outerRadius;
        
        final Offset widgetCenter = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
        final Offset currentCircleOffsetPixels = Offset(
          (displayedWidth / 2) * widget.centerOffset.dx,
          (displayedHeight / 2) * widget.centerOffset.dy,
        );
        final Offset circleCenter = widgetCenter + currentCircleOffsetPixels;

        return Stack(
          alignment: Alignment.center,
          children: [
            Image.file(
              File(widget.activeImage.imagePath),
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                
                onPanStart: (details) {
                  final touchPoint = details.localPosition;
                  final distance = (touchPoint - circleCenter).distance;
                  
                  if ((distance - pixelRadius).abs() < 30.0) {
                    _isResizing = true;
                  } else {
                    _isResizing = false;
                  }
                },

                onPanUpdate: (details) {
                  if (_isResizing) {
                    final touchPoint = details.localPosition;
                    final newDistance = (touchPoint - circleCenter).distance;
                    double newRadiusPercent = newDistance / baseRadius;
                    widget.onRadiusChange(newRadiusPercent.clamp(0.1, 1.0));
                  } else {
                    final dx = details.delta.dx / (displayedWidth / 2);
                    final dy = details.delta.dy / (displayedHeight / 2);
                    widget.onPanUpdate(Offset(dx, dy));
                  }
                },
                child: CustomPaint(
                  painter: IrisSelectionPainter(
                    outerRadiusPercent: widget.outerRadius,
                    innerRadiusPercent: widget.innerRadius,
                    ovalRatio: widget.ovalRatio,
                    centerOffsetPercent: widget.centerOffset,
                    imageRect: imageRect,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    Gap(12),
                    Expanded(
                      child: Text(
                        "Drag center to move. Drag edge to resize.",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class IrisSelectionPainter extends CustomPainter {
  final double outerRadiusPercent;
  final double innerRadiusPercent;
  final double ovalRatio;
  final Offset centerOffsetPercent;
  final Rect imageRect;

  IrisSelectionPainter({
    required this.outerRadiusPercent,
    required this.innerRadiusPercent,
    required this.ovalRatio,
    required this.centerOffsetPercent,
    required this.imageRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = imageRect.center + 
        Offset(
          (imageRect.width / 2) * centerOffsetPercent.dx, 
          (imageRect.height / 2) * centerOffsetPercent.dy
        );

    final double baseRadius = imageRect.shortestSide / 2;
    
    final double outerWidth = baseRadius * outerRadiusPercent * 2;
    final double outerHeight = outerWidth * ovalRatio;
    final double innerWidth = baseRadius * innerRadiusPercent * 2;
    final double innerHeight = innerWidth; 

    final Rect outerRect = Rect.fromCenter(center: center, width: outerWidth, height: outerHeight);
    final Rect innerRect = Rect.fromCenter(center: center, width: innerWidth, height: innerHeight);

    final Paint maskPaint = Paint()..color = Colors.black.withOpacity(0.8)..style = PaintingStyle.fill;
    Path backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    Path irisPath = Path()
      ..addOval(outerRect)
      ..addOval(innerRect)
      ..fillType = PathFillType.evenOdd;
    
    canvas.drawPath(Path.combine(PathOperation.difference, backgroundPath, irisPath), maskPaint);

    final Paint borderPaint = Paint()..color = Colors.blueAccent..style = PaintingStyle.stroke..strokeWidth = 2.0;
    canvas.drawOval(outerRect, borderPaint);

    final Paint pupilPaint = Paint()..color = Colors.redAccent..style = PaintingStyle.stroke..strokeWidth = 2.0;
    canvas.drawOval(innerRect, pupilPaint);
    
    final Paint crossPaint = Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 1;
    canvas.drawLine(center - const Offset(10, 0), center + const Offset(10, 0), crossPaint);
    canvas.drawLine(center - const Offset(0, 10), center + const Offset(0, 10), crossPaint);
  }

  @override
  bool shouldRepaint(covariant IrisSelectionPainter oldDelegate) {
    return oldDelegate.outerRadiusPercent != outerRadiusPercent ||
           oldDelegate.innerRadiusPercent != innerRadiusPercent ||
           oldDelegate.centerOffsetPercent != centerOffsetPercent ||
           oldDelegate.ovalRatio != ovalRatio ||
           oldDelegate.imageRect != imageRect;
  }
}