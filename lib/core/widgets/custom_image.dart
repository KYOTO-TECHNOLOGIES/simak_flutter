import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uae_ecom_project/core/network/image_cache_manager.dart';

class CustomImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final EdgeInsetsGeometry padding;

  const CustomImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('assets/')) {
      return Padding(
        padding: padding,
        child: Image.asset(
          url,
          width: width,
          height: height,
          fit: BoxFit.contain,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: CustomImageCacheManager.instance,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        return Padding(
          padding: padding,
          child: Image.asset(
            'assets/images/home_logo.png',
            width: width,
            height: height,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }

  /// Helper to get a cached provider for cases like BoxDecoration
  static ImageProvider provider(String url) {
    if (url.startsWith('assets/')) {
      return AssetImage(url);
    }
    return CachedNetworkImageProvider(
      url,
      cacheManager: CustomImageCacheManager.instance,
    );
  }
}
