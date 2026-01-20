import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as ui;
import 'package:flutter_gap/flutter_gap.dart';
import 'package:iris_designer/Features/EDITOR/Domain/entities/iris_image.dart';
import 'package:path_provider/path_provider.dart';

class FlashCorrectionView extends StatefulWidget {
  final IrisImage activeImage;
  final Function(String newPath) onImageUpdated;

  const FlashCorrectionView({
    super.key,
    required this.activeImage,
    required this.onImageUpdated,
  });

  @override
  FlashCorrectionViewState createState() => FlashCorrectionViewState();
}

// ✅ Made Public (removed '_') so Parent can access saveImage() via GlobalKey
class FlashCorrectionViewState extends State<FlashCorrectionView> {
  // Stores strokes in IMAGE COORDINATES
  final List<CloneStroke> _strokes = [];
  
  // Current active stroke data
  List<Offset>? _currentStrokePoints;
  Offset? _currentStrokeShift;

  double _brushSize = 40.0; 
  bool _isSaving = false;
  ui.Image? _baseImage;
  
  // Zoom State
  double _zoom = 1.0; 
  
  // Clone Stamp State
  bool _isPickingSource = false;
  Offset? _sourcePoint; 

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant FlashCorrectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeImage.imagePath != widget.activeImage.imagePath) {
      _loadImage();
      _strokes.clear();
      _sourcePoint = null;
      _zoom = 1.0;
    }
  }

  Future<void> _loadImage() async {
    final data = await File(widget.activeImage.imagePath).readAsBytes();
    final image = await decodeImageFromList(data);
    if (mounted) {
      setState(() {
        _baseImage = image;
        // Default source to center
        _sourcePoint ??= Offset(image.width / 2.0, image.height / 2.0);
      });
    }
  }

  // ✅ PUBLIC SAVE METHOD: Only called when "Apply Changes" is pressed
  Future<void> saveImage() async {
    if (_baseImage == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      // 1. Setup a recorder to draw the FULL image (1:1 scale)
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // 2. Use the painter to draw the base image + all strokes
      final painter = _ClonePainter(
        image: _baseImage!,
        strokes: _strokes,
        brushSize: 0,
        scale: 1.0,   // Full scale
        offset: Offset.zero, // No offset
        sourcePoint: null, // Don't draw UI indicators on saved file
        isPicking: false,
      );
      
      // Paint onto a canvas sized exactly like the original image
      painter.paint(canvas, ui.Size(_baseImage!.width.toDouble(), _baseImage!.height.toDouble()));
      
      // 3. Convert to Image
      final picture = recorder.endRecording();
      final img = await picture.toImage(_baseImage!.width, _baseImage!.height);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final directory = await getTemporaryDirectory(); 
        final String newPath = '${directory.path}/flash_corrected_${DateTime.now().millisecondsSinceEpoch}.png';
        final File newFile = File(newPath);
        await newFile.writeAsBytes(byteData.buffer.asUint8List());
        
        // Notify Parent
        widget.onImageUpdated(newPath);
      }
    } catch (e) {
      debugPrint("Error saving: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ✅ Painting Canvas
        LayoutBuilder(
          builder: (context, constraints) {
            if (_baseImage == null) return const Center(child: CircularProgressIndicator());

            // 1. Calculate Base Scale to fit image on screen
            final double baseScaleX = constraints.maxWidth / _baseImage!.width;
            final double baseScaleY = constraints.maxHeight / _baseImage!.height;
            final double baseScale = baseScaleX < baseScaleY ? baseScaleX : baseScaleY;

            // 2. Apply Visual Zoom
            final double currentScale = baseScale * _zoom;

            // 3. Center the image
            final double renderedWidth = _baseImage!.width * currentScale;
            final double renderedHeight = _baseImage!.height * currentScale;
            final double dx = (constraints.maxWidth - renderedWidth) / 2;
            final double dy = (constraints.maxHeight - renderedHeight) / 2;
            final Offset imgOffset = Offset(dx, dy);

            return GestureDetector(
              behavior: HitTestBehavior.opaque, 
              onTapUp: (details) {
                if (_isPickingSource) {
                  setState(() {
                    _sourcePoint = (details.localPosition - imgOffset) / currentScale;
                    _isPickingSource = false; 
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Source Set"), duration: Duration(milliseconds: 500)));
                }
              },
              onPanStart: (details) {
                if (_isPickingSource) return;
                
                setState(() {
                  // Map screen touch -> Image Coordinate
                  Offset localImgPos = (details.localPosition - imgOffset) / currentScale;
                  Offset source = _sourcePoint ?? Offset(_baseImage!.width/2, _baseImage!.height/2);
                  
                  // Calculate shift for this stroke
                  _currentStrokeShift = localImgPos - source;
                  _currentStrokePoints = [localImgPos];
                });
              },
              onPanUpdate: (details) {
                if (_isPickingSource || _currentStrokePoints == null) return;
                
                setState(() {
                  Offset localImgPos = (details.localPosition - imgOffset) / currentScale;
                  _currentStrokePoints!.add(localImgPos);
                });
              },
              onPanEnd: (details) {
                if (_isPickingSource || _currentStrokePoints == null) return;
                
                setState(() {
                  // Commit stroke to memory (UI updates instantly)
                  _strokes.add(CloneStroke(
                    points: List.from(_currentStrokePoints!),
                    shift: _currentStrokeShift!,
                    brushSize: _brushSize 
                  ));
                  _currentStrokePoints = null;
                  _currentStrokeShift = null;
                });
                // Note: Removed _saveResult() here. Saving is now manual.
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: _ClonePainter(
                  image: _baseImage!,
                  strokes: _strokes,
                  currentPoints: _currentStrokePoints,
                  currentShift: _currentStrokeShift,
                  brushSize: _brushSize,
                  scale: currentScale, 
                  offset: imgOffset,   
                  sourcePoint: _sourcePoint,
                  isPicking: _isPickingSource,
                ),
              ),
            );
          }
        ),

        if (_isSaving) const Center(child: CircularProgressIndicator()),

        // ✅ Toolbar (Left) with Tooltips and Logic
        Positioned(
          top: 20, left: 20,
          child: Column(
            children: [
              // UNDO BUTTON
              _buildBtn("Undo Last Stroke", Icons.undo, false, () {
                if (_strokes.isNotEmpty) {
                  setState(() => _strokes.removeLast());
                }
              }),
              const Gap(8),
              
              // TARGET BUTTON
              _buildBtn("Set Source Point", Icons.gps_fixed, _isPickingSource, () => setState(() => _isPickingSource = true)), 
              const Gap(8),
              
              // BRUSH BUTTON
              _buildBtn("Paint Tool", Icons.brush, !_isPickingSource, () => setState(() => _isPickingSource = false)),
              const Gap(16),
              
              // RESET BUTTON (Reverts All Changes)
              _buildBtn("Reset All Changes", Icons.refresh, false, () {
                setState(() {
                  _strokes.clear();
                  _zoom = 1.0;
                  if (_baseImage != null) {
                    _sourcePoint = Offset(_baseImage!.width / 2.0, _baseImage!.height / 2.0);
                  }
                });
              }),
            ],
          ),
        ),

        // ✅ Top Right Controls
        Positioned(
          top: 20, 
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Zoom Buttons
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3441),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildZoomBtn("Zoom Out", Icons.remove, () {
                      setState(() {
                        if (_zoom > 1.0) _zoom -= 0.5;
                        if (_zoom < 1.0) _zoom = 1.0;
                      });
                    }),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        "${(_zoom * 100).toInt()}%",
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    _buildZoomBtn("Zoom In", Icons.add, () {
                      setState(() {
                        if (_zoom < 5.0) _zoom += 0.5;
                      });
                    }),
                  ],
                ),
              ),
              const Gap(16),
              
              // Brush Slider (Hidden if Picking Source)
              if (!_isPickingSource)
                Container(
                  width: 200, 
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF2A3441), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.brush, size: 14, color: Colors.white),
                      Expanded(
                        child: Slider(
                          value: _brushSize,
                          min: 10.0,
                          max: 150.0,
                          onChanged: (v) => setState(() => _brushSize = v),
                          activeColor: Colors.blue,
                          inactiveColor: Colors.grey,
                        ),
                      ),
                      Text(
                        "${_brushSize.toInt()}px",
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        if(_isPickingSource)
          Positioned(bottom: 20, left: 0, right: 0, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(20)), child: const Text("Tap Clean Area to Copy From", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
      ],
    );
  }

  // Helper with Tooltip
  Widget _buildBtn(String tooltip, IconData icon, bool active, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: active ? Colors.blue : const Color(0xFF2A3441), borderRadius: BorderRadius.circular(8), border: active ? Border.all(color: Colors.white) : null),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildZoomBtn(String tooltip, IconData icon, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class CloneStroke {
  final List<Offset> points; 
  final Offset shift;        
  final double brushSize;

  CloneStroke({required this.points, required this.shift, required this.brushSize});
}

class _ClonePainter extends CustomPainter {
  final ui.Image image;
  final List<CloneStroke> strokes;
  final List<Offset>? currentPoints;
  final Offset? currentShift;
  final double brushSize;
  final double scale;
  final Offset offset;
  final Offset? sourcePoint;
  final bool isPicking;

  _ClonePainter({
    required this.image,
    required this.strokes,
    this.currentPoints,
    this.currentShift,
    required this.brushSize,
    required this.scale,
    required this.offset,
    required this.sourcePoint,
    required this.isPicking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.black);

    // 2. Transform Canvas to Image Space
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // 3. Draw Base Image
    canvas.drawImage(image, Offset.zero, Paint());

    // 4. Draw Strokes
    for (final stroke in strokes) {
      _drawStrokePath(canvas, stroke.points, stroke.shift, stroke.brushSize);
    }

    if (currentPoints != null && currentShift != null) {
      _drawStrokePath(canvas, currentPoints!, currentShift!, brushSize);
    }

    canvas.restore(); 

    // 5. Draw UI Indicators
    if (sourcePoint != null && isPicking) {
      final screenSource = (sourcePoint! * scale) + offset;
      final Paint border = Paint()..color = Colors.greenAccent..style = PaintingStyle.stroke..strokeWidth = 2;
      canvas.drawCircle(screenSource, 15, border); 
      canvas.drawLine(screenSource - const Offset(20,0), screenSource + const Offset(20,0), border);
      canvas.drawLine(screenSource - const Offset(0,20), screenSource + const Offset(0,20), border);
    }
  }

  void _drawStrokePath(Canvas canvas, List<Offset> points, Offset shift, double size) {
    Rect imageBounds = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    for (int i = 0; i < points.length; i++) {
      if (i > 0 && (points[i] - points[i-1]).distance < size / 4) continue;

      Offset dest = points[i];
      Offset src = dest - shift; 

      Rect srcRect = Rect.fromCenter(center: src, width: size, height: size);
      Rect dstRect = Rect.fromCenter(center: dest, width: size, height: size);

      // SAFETY CHECK: Only draw parts inside image bounds
      Rect safeSrc = srcRect.intersect(imageBounds);
      if (safeSrc.isEmpty) continue;

      double leftTrim = safeSrc.left - srcRect.left;
      double topTrim = safeSrc.top - srcRect.top;
      
      Rect safeDst = Rect.fromLTWH(dstRect.left + leftTrim, dstRect.top + topTrim, safeSrc.width, safeSrc.height);

      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(dstRect, Radius.circular(size/2)));
      canvas.drawImageRect(image, safeSrc, safeDst, Paint());
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}