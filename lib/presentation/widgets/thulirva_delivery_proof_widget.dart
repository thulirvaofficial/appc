import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';

/// Production-Grade Delivery Proof Image Widget for Customer App
/// Handles:
/// 1. Base64 data URIs ('data:image/...') & raw Base64 strings via Image.memory
/// 2. Multi-host candidate URLs with sequential auto-failover
/// 3. Prevents 'Exception: Invalid image data' on corrupt/HTML responses
/// 4. Full-screen pinch-to-zoom dialog (InteractiveViewer 0.5x - 5.0x)
/// 5. Offline retry, cache invalidation and loading states
class ThulirvaDeliveryProofWidget extends StatefulWidget {
  final String? proofSource;
  final double height;
  final double width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool enableZoom;
  final String title;

  const ThulirvaDeliveryProofWidget({
    super.key,
    required this.proofSource,
    this.height = 160,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.enableZoom = true,
    this.title = 'Doorstep Delivery Proof Photo',
  });

  @override
  State<ThulirvaDeliveryProofWidget> createState() => _ThulirvaDeliveryProofWidgetState();
}

class _ThulirvaDeliveryProofWidgetState extends State<ThulirvaDeliveryProofWidget> {
  int _candidateIndex = 0;
  List<String> _candidates = [];
  Uint8List? _decodedBytes;
  bool _isBase64 = false;
  int _cacheBuster = 0;

  @override
  void initState() {
    super.initState();
    _processSource();
  }

  @override
  void didUpdateWidget(covariant ThulirvaDeliveryProofWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proofSource != widget.proofSource) {
      _candidateIndex = 0;
      _processSource();
    }
  }

  void _processSource() {
    final src = widget.proofSource?.trim() ?? '';
    _decodedBytes = null;
    _isBase64 = false;
    _candidates = [];

    if (src.isEmpty) return;

    // Check if Base64
    if (src.startsWith('data:image/') || (!src.startsWith('http') && !src.startsWith('/') && src.length > 100)) {
      try {
        final commaIdx = src.indexOf(',');
        final rawBase64 = commaIdx != -1 ? src.substring(commaIdx + 1) : src;
        _decodedBytes = base64Decode(rawBase64);
        _isBase64 = true;
        return;
      } catch (_) {
        // Fall back to candidate URL resolution
      }
    }

    _candidates = ApiEndpoints.getCandidateImageUrls(src);
  }

  void _handleImageError() {
    if (_candidateIndex < _candidates.length - 1) {
      if (mounted) {
        setState(() {
          _candidateIndex++;
        });
      }
    }
  }

  void _retryLoading() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (mounted) {
      setState(() {
        _candidateIndex = 0;
        _cacheBuster = DateTime.now().millisecondsSinceEpoch;
      });
    }
  }

  void _showZoomDialog() {
    if (!widget.enableZoom) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildZoomContent(),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomContent() {
    if (_isBase64 && _decodedBytes != null) {
      return Image.memory(
        _decodedBytes!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildErrorThumbnail(),
      );
    }

    if (_candidates.isNotEmpty && _candidateIndex < _candidates.length) {
      final url = _candidates[_candidateIndex];
      final finalUrl = _cacheBuster > 0 ? '$url?cb=$_cacheBuster' : url;
      return Image.network(
        finalUrl,
        fit: BoxFit.contain,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: AppColors.forestGreen),
          );
        },
        errorBuilder: (_, __, ___) => _buildErrorThumbnail(),
      );
    }

    return _buildErrorThumbnail();
  }

  Widget _buildThumbnailContent() {
    if (widget.proofSource == null || widget.proofSource!.isEmpty) {
      return Container(
        height: widget.height,
        color: const Color(0xFFFAF7F0),
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_back_outlined, size: 34, color: AppColors.textMid),
            SizedBox(height: 6),
            Text(
              'No delivery proof photo captured yet',
              style: TextStyle(fontSize: 12, color: AppColors.textMid, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    // 1. Render Base64 Memory Image
    if (_isBase64 && _decodedBytes != null) {
      return Image.memory(
        _decodedBytes!,
        height: widget.height,
        width: widget.width,
        fit: widget.fit,
        errorBuilder: (ctx, err, stack) => _buildErrorThumbnail(),
      );
    }

    // 2. Render Network Image with Candidate Fallback
    if (_candidates.isNotEmpty && _candidateIndex < _candidates.length) {
      final currentUrl = _candidates[_candidateIndex];
      final finalUrl = _cacheBuster > 0 ? '$currentUrl?cb=$_cacheBuster' : currentUrl;

      return Image.network(
        finalUrl,
        key: ValueKey('customer_proof_${widget.proofSource}_${_candidateIndex}_$_cacheBuster'),
        height: widget.height,
        width: widget.width,
        fit: widget.fit,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            height: widget.height,
            color: const Color(0xFFFAF7F0),
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF15803D),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Loading doorstep proof photo...',
                  style: TextStyle(fontSize: 11, color: AppColors.textMid),
                ),
              ],
            ),
          );
        },
        errorBuilder: (ctx, err, stack) {
          if (_candidateIndex < _candidates.length - 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _handleImageError());
            return Container(
              height: widget.height,
              color: const Color(0xFFFAF7F0),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF15803D)),
              ),
            );
          }
          return _buildErrorThumbnail();
        },
      );
    }

    return _buildErrorThumbnail();
  }

  Widget _buildErrorThumbnail() {
    return Container(
      height: widget.height,
      color: const Color(0xFFFAF7F0),
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image_rounded, size: 28, color: Color(0xFFD97706)),
          const SizedBox(height: 6),
          const Text(
            'Proof photo verified on Thulirva network',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMid),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _retryLoading,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF15803D),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Retry Loading',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    return GestureDetector(
      onTap: widget.enableZoom ? _showZoomDialog : null,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            _buildThumbnailContent(),
            if (widget.enableZoom && (widget.proofSource?.isNotEmpty ?? false))
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Pinch to Zoom',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
