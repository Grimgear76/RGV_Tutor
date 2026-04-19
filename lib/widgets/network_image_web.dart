import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

class NetworkImageView extends StatefulWidget {
  const NetworkImageView({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
    this.fallback,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;

  @override
  State<NetworkImageView> createState() => _NetworkImageViewState();
}

class _NetworkImageViewState extends State<NetworkImageView> {
  static int _counter = 0;

  late final String _viewType;
  late final html.ImageElement _element;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _viewType = 'network-image-${widget.url.hashCode}-${_counter++}';
    _element = html.ImageElement()
      ..src = widget.url
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = _cssObjectFit(widget.fit)
      ..style.display = 'block';

    final radius = widget.borderRadius;
    if (radius != null) {
      _element.style.borderRadius = _cssBorderRadius(radius);
      _element.style.overflow = 'hidden';
    }

    _element.onError.listen((_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    });

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) => _element);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return widget.fallback ?? const SizedBox.shrink();

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: _viewType),
    );
  }

  String _cssObjectFit(BoxFit? fit) {
    return switch (fit) {
      BoxFit.cover => 'cover',
      BoxFit.contain => 'contain',
      BoxFit.fill => 'fill',
      BoxFit.fitHeight => 'contain',
      BoxFit.fitWidth => 'contain',
      BoxFit.none => 'none',
      BoxFit.scaleDown => 'scale-down',
      _ => 'contain',
    };
  }

  String _cssBorderRadius(BorderRadius radius) {
    final topLeft = radius.topLeft;
    final topRight = radius.topRight;
    final bottomRight = radius.bottomRight;
    final bottomLeft = radius.bottomLeft;

    String cssRadius(Radius r) {
      if (r.x == r.y) return '${r.x}px';
      return '${r.x}px ${r.y}px';
    }

    return '${cssRadius(topLeft)} ${cssRadius(topRight)} ${cssRadius(bottomRight)} ${cssRadius(bottomLeft)}';
  }
}
