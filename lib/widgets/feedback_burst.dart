import 'package:flutter/material.dart';

class FeedbackBurst extends StatelessWidget {
  const FeedbackBurst({
    super.key,
    required this.correct,
    required this.visible,
  });

  final bool correct;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = correct ? colorScheme.primaryContainer : colorScheme.errorContainer;
    final fg = correct ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer;

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        child: Center(
          child: AnimatedScale(
            scale: visible ? 1 : 0.85,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(correct ? Icons.check_circle : Icons.cancel, color: fg, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    correct ? 'Nice!' : 'Try again',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
