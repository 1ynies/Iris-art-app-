
import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class ImageGrid extends StatelessWidget {
  final List<String> images;
  // ✅ Callback to notify parent when delete is clicked
  final Function(String path) onDelete; 

  const ImageGrid({
    super.key,
    required this.images,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 1. EMPTY STATE
    if (images.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: DottedBorder(
          color: const Color(0xFF687890).withOpacity(0.5),
          strokeWidth: 2,
          dashPattern: const [6, 6],
          borderType: BorderType.RRect,
          radius: const Radius.circular(16),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF181E28),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.add, size: 32, color: Color(0xFF687890)),
            ),
          ),
        ),
      );
    }

    // 2. POPULATED STATE
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final String path = images[index];
        // ✅ Use a separate widget to handle Hover state per item
        return _GridImageItem(
          path: path,
          onDelete: () => onDelete(path),
        );
      },
    );
  }
}

// -----------------------------------------------------------
// 🖱️ HOVERABLE IMAGE ITEM WIDGET
// -----------------------------------------------------------
class _GridImageItem extends StatefulWidget {
  final String path;
  final VoidCallback onDelete;

  const _GridImageItem({required this.path, required this.onDelete});

  @override
  State<_GridImageItem> createState() => _GridImageItemState();
}

class _GridImageItemState extends State<_GridImageItem> {
  bool isHovered = false; // Tracks if mouse is over this specific image

  @override
  Widget build(BuildContext context) {
    final bool isNetworkImage = widget.path.startsWith('http');

    return MouseRegion(
      // ✅ Detect Hover Enter
      onEnter: (_) => setState(() => isHovered = true),
      // ✅ Detect Hover Exit
      onExit: (_) => setState(() => isHovered = false),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. THE IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isNetworkImage
                ? Image.network(
                    widget.path,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      color: const Color(0xFF2A3441),
                      child: const Icon(Icons.broken_image, color: Colors.white54),
                    ),
                  )
                : Image.file(File(widget.path), fit: BoxFit.cover),
          ),

          // 2. DELETE OVERLAY (Only shows when hovered)
          if (isHovered)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4), // Darken background
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 32),
                    onPressed: widget.onDelete,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}