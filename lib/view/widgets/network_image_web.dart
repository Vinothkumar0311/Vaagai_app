import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:flutter/material.dart';

Widget buildNetworkImage({
  required String imageUrl,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  final String viewId = 'img-${imageUrl.hashCode}';

  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final html.ImageElement element = html.ImageElement()
      ..src = imageUrl
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = _getHtmlObjectFit(fit)
      ..style.border = 'none';
    return element;
  });

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewId),
  );
}

String _getHtmlObjectFit(BoxFit fit) {
  switch (fit) {
    case BoxFit.cover:
      return 'cover';
    case BoxFit.contain:
      return 'contain';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.fitWidth:
      return 'fit-width';
    case BoxFit.fitHeight:
      return 'fit-height';
    case BoxFit.scaleDown:
      return 'scale-down';
    case BoxFit.none:
      return 'none';
  }
}
