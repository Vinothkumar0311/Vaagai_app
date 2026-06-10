import 'package:flutter/material.dart';
import 'network_image_stub.dart'
    if (dart.library.html) 'network_image_web.dart'
    if (dart.library.io) 'network_image_mobile.dart';

class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return buildNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
