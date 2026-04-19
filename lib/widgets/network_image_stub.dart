import 'package:flutter/widgets.dart';

const _proxyBaseUrl = String.fromEnvironment('BOOK_PROXY_URL');

class NetworkImageView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final effectiveUrl = _proxyBaseUrl.isEmpty
        ? url
        : Uri.parse(_proxyBaseUrl).replace(queryParameters: {'url': url}).toString();

    final image = Image.network(
      effectiveUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback ?? const SizedBox.shrink(),
    );

    final radius = borderRadius;
    if (radius == null) return image;
    return ClipRRect(borderRadius: radius, child: image);
  }
}
