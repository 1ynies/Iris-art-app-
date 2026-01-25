import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iris_designer/Features/EDITOR/Domain/entities/iris_image.dart';

enum _DragMode { none, moveOuter, moveInner, resizeOuter, resizeInner }

class CirclingView extends StatefulWidget {
  final IrisImage activeImage;
  final double outerRadius;
  final double innerRadius;
  final double ovalRatio;
  final Offset outerCenterOffset;
  final Offset innerCenterOffset;
  final void Function(double dx, double dy) onOuterPan;
  final void Function(double dx, double dy) onInnerPan;
  final void Function(double r) onOuterRadiusChange;
  final void Function(double r) onInnerRadiusChange;
  final void Function(double ratio) onOvalRatioChange;
  final void Function(Size size)? onLayoutSize;

  const CirclingView({
    super.key,
    required this.activeImage,
    required this.outerRadius,
    required this.innerRadius,
    required this.ovalRatio,
    required this.outerCenterOffset,
    required this.innerCenterOffset,
    required this.onOuterPan,
    required this.onInnerPan,
    required this.onOuterRadiusChange,
    required this.onInnerRadiusChange,
    required this.onOvalRatioChange,
    this.onLayoutSize,
  });

  @override
  State<CirclingView> createState() => _CirclingViewState();
}

class _CirclingViewState extends State<CirclingView> {
  _DragMode _mode = _DragMode.none;
  Offset? _resizeStartPos;
  Offset? _resizeStartCenter;
  double? _resizeStartRadius;
  static const double _edgeHitMargin = 20.0; // Increased for better touch

  double _shortestSide(double vw, double vh) => vw < vh ? vw : vh;

  Offset _outerCenter(double vw, double vh) => Offset(
    (vw / 2) + (vw * widget.outerCenterOffset.dx),
    (vh / 2) + (vh * widget.outerCenterOffset.dy),
  );

  Offset _innerCenter(double vw, double vh) => Offset(
    (vw / 2) + (vw * widget.innerCenterOffset.dx),
    (vh / 2) + (vh * widget.innerCenterOffset.dy),
  );

  _DragMode _hitTest(double vw, double vh, Offset p) {
    final oc = _outerCenter(vw, vh);
    final ic = _innerCenter(vw, vh);
    final or = widget.outerRadius * (_shortestSide(vw, vh) / 2);
    final ir = widget.innerRadius * (_shortestSide(vw, vh) / 2);

    if ((p - ic).distance < _edgeHitMargin + ir && (p - ic).distance > ir - _edgeHitMargin) return _DragMode.resizeInner;
    if ((p - ic).distance < ir) return _DragMode.moveInner;
    
    // Simple ellipse hit test for resize/move
    final u = (p.dx - oc.dx) / or;
    final v = (p.dy - oc.dy) / (or * widget.ovalRatio);
    final dist = u * u + v * v;
    if ((dist - 1.0).abs() < 0.2) return _DragMode.resizeOuter;
    if (dist < 1.0) return _DragMode.moveOuter;

    return _DragMode.none;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final double vw = constraints.maxWidth;
        final double vh = constraints.maxHeight;
        widget.onLayoutSize?.call(Size(vw, vh));

        final shortestSide = _shortestSide(vw, vh);
        final outerCenter = _outerCenter(vw, vh);
        final innerCenter = _innerCenter(vw, vh);
        final or = widget.outerRadius * (shortestSide / 2);
        final ir = widget.innerRadius * (shortestSide / 2);

        return GestureDetector(
          onPanStart: (d) {
            _mode = _hitTest(vw, vh, d.localPosition);
            if (_mode == _DragMode.resizeOuter) {
              _resizeStartPos = d.localPosition;
              _resizeStartCenter = outerCenter;
              _resizeStartRadius = widget.outerRadius;
            }
          },
          onPanUpdate: (d) {
            final pos = d.localPosition;
            if (_mode == _DragMode.moveOuter) {
              widget.onOuterPan(d.delta.dx / vw, d.delta.dy / vh);
            } else if (_mode == _DragMode.moveInner) {
              widget.onInnerPan(d.delta.dx / vw, d.delta.dy / vh);
            } else if (_mode == _DragMode.resizeInner) {
              final r = (pos - innerCenter).distance;
              widget.onInnerRadiusChange(r / (shortestSide / 2));
            } else if (_mode == _DragMode.resizeOuter && _resizeStartCenter != null) {
              final dx = (pos.dx - _resizeStartCenter!.dx).abs();
              final dy = (pos.dy - _resizeStartCenter!.dy).abs();
              // Logic to handle oval or circle resizing based on drag direction
              if (dx > dy) {
                widget.onOuterRadiusChange(dx / (shortestSide / 2));
              } else {
                widget.onOvalRatioChange(dy / (widget.outerRadius * shortestSide / 2));
              }
            }
          },
          onPanEnd: (_) => _mode = _DragMode.none,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.file(
                  File(widget.activeImage.imagePath),
                  // FIXED: When it's already cut, use BoxFit.contain so it fills nicely
                  fit: widget.activeImage.isCirclingDone ? BoxFit.contain : BoxFit.contain,
                ),
              ),
              CustomPaint(
                size: Size.infinite,
                painter: _OverlayPainter(outerCenter, innerCenter, or, ir, widget.ovalRatio),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Offset outerCenter;
  final Offset innerCenter;
  final double or;
  final double ir;
  final double ratio;

  _OverlayPainter(this.outerCenter, this.innerCenter, this.or, this.ir, this.ratio);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()..style = PaintingStyle.stroke..strokeWidth = 2;
    // Outer Circle (Blue)
    stroke.color = Colors.blueAccent;
    canvas.drawOval(Rect.fromCenter(center: outerCenter, width: or * 2, height: or * 2 * ratio), stroke);
    // Inner Circle (Red)
    stroke.color = Colors.redAccent;
    canvas.drawCircle(innerCenter, ir, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}