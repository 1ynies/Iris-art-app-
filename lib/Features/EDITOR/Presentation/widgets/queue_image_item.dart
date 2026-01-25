import 'dart:io';

import 'package:flutter/material.dart';

// Assuming this entity exists in your project structure
import 'package:iris_designer/Features/EDITOR/Domain/entities/iris_image.dart';

class QueueImageItem extends StatefulWidget {
  final IrisImage img;
  final bool isSelected;
  final bool isDone;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const QueueImageItem({
    required this.img,
    required this.isSelected,
    required this.isDone,
    required this.onTap,
    required this.onRemove,
  });

  @override
  _QueueImageItemState createState() => _QueueImageItemState();
}

class _QueueImageItemState extends State<QueueImageItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? Colors.blueAccent
        : (widget.isDone ? Colors.green : Colors.transparent);
    final badgeColor = widget.isSelected
        ? Colors.blueAccent
        : (widget.isDone ? Colors.green : Colors.grey.withOpacity(0.8));
    final badgeText = widget.isSelected
        ? "EDITING"
        : (widget.isDone ? "DONE" : "PENDING");

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: (widget.isSelected || widget.isDone) ? 2 : 0,
            ),
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF2A3441),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: ColorFiltered(
                  colorFilter: (!widget.isSelected && !widget.isDone)
                      ? const ColorFilter.mode(Colors.black54, BlendMode.darken)
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.dst,
                        ),
                  child: Image.file(
                    File(widget.img.imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (_isHovered)
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () => widget.onRemove(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
