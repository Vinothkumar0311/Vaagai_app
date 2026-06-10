import 'package:flutter/material.dart';

Widget buildNetworkImage({
  required String imageUrl,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  return Image.network(
    imageUrl,
    width: width,
    height: height,
    fit: fit,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
    },
    errorBuilder: (_, __, ___) => const Center(
      child: Icon(Icons.school_rounded, size: 48, color: Color(0xFF1B5E20)),
    ),
  );
}
