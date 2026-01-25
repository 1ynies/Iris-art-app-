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
  static const double _edgeHitMargin = 14.0;
  static const double _minRadiusVal = 0.05;
  static const double _maxRadiusVal = 1.0;
  static const double _minOvalRatio = 0.3;
  static const double _maxOvalRatio = 2.0;

  double _shortestSide(double vw, double vh) => vw < vh ? vw : vh;

  Offset _outerCenter(double vw, double vh) => Offset(
    (vw / 2) + (vw * widget.outerCenterOffset.dx),
    (vh / 2) + (vh * widget.outerCenterOffset.dy),
  );

  Offset _innerCenter(double vw, double vh) => Offset(
    (vw / 2) + (vw * widget.innerCenterOffset.dx),
    (vh / 2) + (vh * widget.innerCenterOffset.dy),
  );

  double _outerR(double vw, double vh) =>
      widget.outerRadius * (_shortestSide(vw, vh) / 2);

  double _innerR(double vw, double vh) =>
      widget.innerRadius * (_shortestSide(vw, vh) / 2);

  double _outerRy(double vw, double vh) => _outerR(vw, vh) * widget.ovalRatio;

  bool _isInsideCircle(Offset c, double r, Offset p) {
    return (p - c).distance <= r;
  }

  bool _isNearCircleEdge(Offset c, double r, Offset p) {
    final d = (p - c).distance;
    return (d - r).abs() <= _edgeHitMargin;
  }

  bool _isInsideEllipse(Offset c, double rx, double ry, Offset p) {
    final u = (p.dx - c.dx) / rx;
    final v = (p.dy - c.dy) / ry;
    return u * u + v * v <= 1.0;
  }

  bool _isNearEllipseEdge(Offset c, double rx, double ry, Offset p) {
    final u = (p.dx - c.dx) / rx;
    final v = (p.dy - c.dy) / ry;
    final f = u * u + v * v;
    return (f - 1.0).abs() <= 0.15;
  }

  /// Determines which side of the ellipse is being dragged
  /// Returns true if horizontal (left/right), false if vertical (top/bottom)
  bool _isHorizontalDrag(Offset center, double rx, double ry, Offset point) {
    final dx = (point.dx - center.dx).abs();
    final dy = (point.dy - center.dy).abs();
    // Compare normalized distances to determine which side is closer
    final normalizedDx = dx / rx;
    final normalizedDy = dy / ry;
    return normalizedDx > normalizedDy;
  }

  _DragMode _hitTest(double vw, double vh, Offset p) {
    final oc = _outerCenter(vw, vh);
    final ic = _innerCenter(vw, vh);
    final or = _outerR(vw, vh);
    final ory = _outerRy(vw, vh);
    final ir = _innerR(vw, vh);

    if (_isNearEllipseEdge(oc, or, ory, p)) return _DragMode.resizeOuter;
    if (_isNearCircleEdge(ic, ir, p)) return _DragMode.resizeInner;
    if (_isInsideCircle(ic, ir, p)) return _DragMode.moveInner;
    if (_isInsideEllipse(oc, or, ory, p)) return _DragMode.moveOuter;
    return _DragMode.none;
  }

  double _radiusValFromDistance(double dist, double vw, double vh) {
    final half = _shortestSide(vw, vh) / 2;
    if (half <= 0) return widget.outerRadius;
    return (dist / half).clamp(_minRadiusVal, _maxRadiusVal);
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
            final delta = d.delta;
            if (_mode == _DragMode.moveOuter) {
              widget.onOuterPan(delta.dx / vw, delta.dy / vh);
            } else if (_mode == _DragMode.moveInner) {
              widget.onInnerPan(delta.dx / vw, delta.dy / vh);
            } else if (_mode == _DragMode.resizeOuter) {
              if (_resizeStartPos != null && _resizeStartCenter != null) {
                final or = _outerR(vw, vh);
                final ory = _outerRy(vw, vh);
                // Determine which side is being dragged based on initial position
                final isHorizontal = _isHorizontalDrag(
                  _resizeStartCenter!,
                  or,
                  ory,
                  _resizeStartPos!,
                );
                
                if (isHorizontal) {
                  // Adjust width (base radius) - use horizontal distance
                  final dx = (pos.dx - _resizeStartCenter!.dx).abs();
                  final shortestSide = _shortestSide(vw, vh);
                  final half = shortestSide / 2;
                  if (half > 0) {
                    final newRadius = (dx / half).clamp(_minRadiusVal, _maxRadiusVal);
                    widget.onOuterRadiusChange(newRadius);
                  }
                } else {
                  // Adjust height (ovalRatio) - use vertical distance
                  final dy = (pos.dy - _resizeStartCenter!.dy).abs();
                  final shortestSide = _shortestSide(vw, vh);
                  final half = shortestSide / 2;
                  if (half > 0 && _resizeStartRadius != null) {
                    final baseRadius = _resizeStartRadius! * half;
                    if (baseRadius > 0) {
                      final newOvalRatio = (dy / baseRadius).clamp(_minOvalRatio, _maxOvalRatio);
                      widget.onOvalRatioChange(newOvalRatio);
                    }
                  }
                }
              }
            } else if (_mode == _DragMode.resizeInner) {
              final r = (pos - innerCenter).distance;
              final val = _radiusValFromDistance(r, vw, vh);
              widget.onInnerRadiusChange(val);
            }
          },
          onPanEnd: (_) {
            _mode = _DragMode.none;
            _resizeStartPos = null;
            _resizeStartCenter = null;
            _resizeStartRadius = null;
          },
          onPanCancel: () {
            _mode = _DragMode.none;
            _resizeStartPos = null;
            _resizeStartCenter = null;
            _resizeStartRadius = null;
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.file(
                File(widget.activeImage.imagePath),
                fit: widget.activeImage.isCirclingDone || widget.activeImage.imagePath.contains('edited_')
                    ? BoxFit.cover
                    : BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
              CustomPaint(
                size: Size.infinite,
                painter: _OverlayPainter(
                  outerCenter,
                  innerCenter,
                  or,
                  ir,
                  widget.ovalRatio,
                ),
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

  _OverlayPainter(
    this.outerCenter,
    this.innerCenter,
    this.or,
    this.ir,
    this.ratio,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    stroke.color = Colors.blue;
    canvas.drawOval(
      Rect.fromCenter(
        center: outerCenter,
        width: or * 2,
        height: or * 2 * ratio,
      ),
      stroke,
    );
    stroke.color = Colors.red;
    canvas.drawOval(
      Rect.fromCenter(center: innerCenter, width: ir * 2, height: ir * 2),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
