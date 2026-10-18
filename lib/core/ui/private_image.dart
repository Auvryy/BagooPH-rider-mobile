import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// A private in-memory preview whose decoded cache entry is evicted on replace
/// and disposal. Resizing affects display only; original upload bytes are intact.
class PrivateImage extends StatefulWidget {
  const PrivateImage({
    super.key,
    required this.bytes,
    required this.label,
    this.onInvalid,
  });
  final Uint8List bytes;
  final String label;
  final VoidCallback? onInvalid;
  @override
  State<PrivateImage> createState() => _PrivateImageState();
}

class _PrivateImageState extends State<PrivateImage> {
  late ImageProvider<Object> _image;
  bool _invalidReported = false;
  ImageProvider<Object> _provider() =>
      ResizeImage.resizeIfNeeded(960, null, MemoryImage(widget.bytes));
  @override
  void initState() {
    super.initState();
    _image = _provider();
  }

  @override
  void didUpdateWidget(PrivateImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes)) {
      unawaited(_image.evict());
      _image = _provider();
      _invalidReported = false;
    }
  }

  @override
  void dispose() {
    unawaited(_image.evict());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Image(
    image: _image,
    height: 200,
    fit: BoxFit.contain,
    semanticLabel: widget.label,
    errorBuilder: (context, error, stack) {
      if (!_invalidReported) {
        _invalidReported = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onInvalid?.call();
        });
      }
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'This image could not be displayed. Choose a valid original image.',
        ),
      );
    },
  );
}
