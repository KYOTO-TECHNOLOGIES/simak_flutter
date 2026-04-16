import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';

class ProductVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnail;

  const ProductVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnail,
  });

  @override
  State<ProductVideoPlayer> createState() => _ProductVideoPlayerState();
}

class _ProductVideoPlayerState extends State<ProductVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  Future<void> _initializePlayer() async {
    if (_isInitialized) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Create controller with encoded URL
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      
      await _videoPlayerController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true, // Auto play once initialized after user tap
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 42),
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () {
                    _chewieController?.dispose();
                    _videoPlayerController?.dispose();
                    _isInitialized = false;
                    _initializePlayer();
                  },
                  child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
                )
              ],
            ),
          );
        },
      );
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If not initialized, show thumbnail with play button
    if (!_isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          if (widget.thumbnail != null)
            Image.network(
              widget.thumbnail!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            )
          else
            Container(color: const Color(0xFF1E1E1E)),
          
          // Dark overlay
          Container(color: Colors.black.withOpacity(0.2)),

          // Play button / Loading indicator
          Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: AppColors.primary)
                : GestureDetector(
                    onTap: _initializePlayer,
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.8), width: 3),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
          ),

          // Error message
          if (_hasError)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Failed to load video',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _initializePlayer,
                      child: const Text('Try Again', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                    )
                  ],
                ),
              ),
            ),
        ],
      );
    }

    // After initialization, show Chewie player
    return Container(
      color: Colors.black,
      child: Chewie(
        controller: _chewieController!,
      ),
    );
  }
}
