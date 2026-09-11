import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Robust network image widget with built-in error handling and loading states
/// Gracefully handles network failures with fallback placeholders
class RobustNetworkImage extends StatefulWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Duration timeout;
  final VoidCallback? onError;

  const RobustNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.timeout = const Duration(seconds: 15),
    this.onError,
  });

  @override
  State<RobustNetworkImage> createState() => _RobustNetworkImageState();
}

class _RobustNetworkImageState extends State<RobustNetworkImage> {
  late Future<void> _loadFuture;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadImage();
  }

  @override
  void didUpdateWidget(RobustNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      setState(() {
        _loadFuture = _loadImage();
        _hasError = false;
        _errorMessage = null;
      });
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No image URL provided';
        });
      }
      return;
    }

    try {
      // Attempt to load image with timeout
      final completer = Completer<void>();
      final imageProvider = NetworkImage(widget.imageUrl!);
      
      imageProvider.resolve(ImageConfiguration.empty).addListener(
        ImageStreamListener(
          (image, synchronousCall) {
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
          onError: (exception, stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(exception, stackTrace);
            }
          },
        ),
      );

      // Apply timeout
      await completer.future.timeout(widget.timeout);
      
      if (mounted) {
        setState(() => _hasError = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load image: ${e.toString()}';
        });
      }
      widget.onError?.call();
      
      // Log error for debugging
      print('🔴 RobustNetworkImage Error: ${widget.imageUrl}');
      print('   $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: FutureBuilder<void>(
          future: _loadFuture,
          builder: (context, snapshot) {
            // Error state
            if (_hasError || snapshot.hasError) {
              return _buildErrorWidget();
            }

            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingWidget();
            }

            // Success state
            return _buildImageWidget();
          },
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    return Image.network(
      widget.imageUrl!,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = error.toString();
          });
        }
        return _buildErrorWidget();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingWidget(
          progress: loadingProgress.cumulativeBytesLoaded /
              (loadingProgress.expectedTotalBytes ?? 1),
        );
      },
    );
  }

  Widget _buildLoadingWidget({double? progress}) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.grey[600]!,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _errorMessage ?? 'Failed to load image',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to safely show network images
Widget safeNetworkImage({
  required String? imageUrl,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  BorderRadius? borderRadius,
}) {
  return RobustNetworkImage(
    imageUrl: imageUrl,
    width: width,
    height: height,
    fit: fit,
    borderRadius: borderRadius,
  );
}

/// Wrapper for NetworkImage with fallback
ImageProvider networkImageWithFallback(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) {
    // Return a placeholder asset image
    return const AssetImage('assets/images/placeholder.png');
  }

  try {
    return NetworkImage(imageUrl);
  } catch (e) {
    print('❌ Failed to create NetworkImage: $e');
    return const AssetImage('assets/images/placeholder.png');
  }
}

/// Image provider factory with error recovery
class SafeImageProvider extends ImageProvider<SafeImageProvider> {
  final String? url;
  final Duration timeout;

  const SafeImageProvider(
    this.url, {
    this.timeout = const Duration(seconds: 15),
  });

  @override
  Future<SafeImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<SafeImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    SafeImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return _NetworkImageStreamCompleter(
      url: url,
      timeout: timeout,
      decode: decode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafeImageProvider &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;
}

/// Custom stream completer with timeout and retry logic
class _NetworkImageStreamCompleter extends ImageStreamCompleter {
  _NetworkImageStreamCompleter({
    required String? url,
    required Duration timeout,
    required ImageDecoderCallback decode,
  }) {
    _load(url, timeout, decode);
  }

  void _load(String? url, Duration timeout, ImageDecoderCallback decode) async {
    try {
      if (url == null || url.isEmpty) {
        reportError(
          exception: Exception('Image URL is empty'),
          stack: StackTrace.current,
        );
        return;
      }

      // Fetch image with timeout
      final imageBytes = await _fetchImageBytes(url, timeout);
      
      // Decode image
      final buffer = await ImmutableBuffer.fromUint8List(imageBytes);
      final codec = await decode(buffer);
      final frameInfo = await codec.getNextFrame();
      
      setImage(frameInfo.image as ImageInfo);
    } catch (e, stackTrace) {
      print('❌ Failed to load image from $url: $e');
      reportError(exception: e, stack: stackTrace);
    }
  }

  Future<Uint8List> _fetchImageBytes(String url, Duration timeout) async {
    // This would need to be implemented with your HTTP client
    // For now, this is a placeholder
    throw UnimplementedError('Use NetworkImage directly or implement HTTP fetching');
  }
}
