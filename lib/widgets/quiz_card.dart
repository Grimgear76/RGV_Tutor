import 'package:flutter/material.dart';

class QuizCard extends StatelessWidget {
  const QuizCard({
    super.key,
    required this.text,
    this.maxHeight,
    this.padding = const EdgeInsets.all(18),
  });

  final String text;
  final double? maxHeight;
  final EdgeInsets padding;

  bool _looksLikeMath(String value) {
    return value.contains('∫') ||
        value.contains('lim') ||
        value.contains('π') ||
        value.contains('→') ||
        value.contains('^') ||
        value.contains('_') ||
        value.contains('sin') ||
        value.contains('cos') ||
        value.contains('tan') ||
        value.contains('ln') ||
        value.contains('e^') ||
        value.contains('d/dx');
  }

  TextStyle _problemTextStyle(BuildContext context, String value) {
    final base = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          height: 1.25,
        );

    if (!_looksLikeMath(value)) return base ?? const TextStyle();
    return (base ?? const TextStyle()).copyWith(fontFamily: 'monospace');
  }

  TextStyle _fitSingleLine(
    BuildContext context, {
    required String value,
    required TextStyle style,
    required double maxWidth,
    required double minFontSize,
  }) {
    final baseSize = style.fontSize ?? Theme.of(context).textTheme.titleLarge?.fontSize ?? 20;
    var low = minFontSize;
    var high = baseSize;

    bool fits(double size) {
      final painter = TextPainter(
        text: TextSpan(text: value, style: style.copyWith(fontSize: size)),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);
      return !painter.didExceedMaxLines;
    }

    if (fits(high)) return style;

    for (var i = 0; i < 12; i++) {
      final mid = (low + high) / 2;
      if (fits(mid)) {
        low = mid;
      } else {
        high = mid;
      }
    }

    return style.copyWith(fontSize: low);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: maxHeight == null ? null : BoxConstraints(maxHeight: maxHeight!),
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final style = _problemTextStyle(context, text);
          final isMath = _looksLikeMath(text);

          if (isMath) {
            final fitted = _fitSingleLine(
              context,
              value: text,
              style: style,
              maxWidth: box.maxWidth,
              minFontSize: 16,
            );

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: box.maxWidth),
                child: Text(
                  text,
                  maxLines: 1,
                  softWrap: false,
                  style: fitted,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Text(
              text,
              textAlign: TextAlign.start,
              style: style,
            ),
          );
        },
      ),
    );
  }
}

