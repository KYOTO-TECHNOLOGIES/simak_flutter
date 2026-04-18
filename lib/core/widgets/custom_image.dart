import 'package:flutter/material.dart';

class CustomImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CustomImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('assets/')) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Image.asset(
          url,
          width: width,
          height: height,
          fit: BoxFit.contain,
        ),
      );
    }
    
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
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
}
