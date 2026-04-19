import 'package:flutter/material.dart';

import '../app_navigator.dart';
import '../services/ollama_chat_service.dart';

class HelperBotPlacement extends InheritedWidget {
  const HelperBotPlacement({super.key, required this.corner, required super.child});

  final HelperBotCorner corner;

  static HelperBotCorner cornerOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HelperBotPlacement>()?.corner ?? HelperBotCorner.bottomLeft;
  }

  @override
  bool updateShouldNotify(HelperBotPlacement oldWidget) => corner != oldWidget.corner;
}

enum HelperBotCorner { topRight, bottomLeft }

class HelperBotLauncher extends StatefulWidget {
  const HelperBotLauncher({super.key});

  @override
  State<HelperBotLauncher> createState() => _HelperBotLauncherState();
}

class _HelperBotLauncherState extends State<HelperBotLauncher> {
  final _service = OllamaChatService();
  bool _sheetOpen = false;
  Offset? _position;

  Future<void> _open() async {
    if (_sheetOpen) return;
    final navigatorContext = appNavigatorKey.currentContext;
    if (navigatorContext == null) return;

    setState(() {
      _sheetOpen = true;
    });

    try {
      await showModalBottomSheet<void>(
        context: navigatorContext,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        useRootNavigator: true,
        builder: (context) => _HelperBotSheet(service: _service),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _sheetOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sheetOpen) return const SizedBox.shrink();

    final viewInsets = MediaQuery.viewInsetsOf(context);
    final padding = MediaQuery.paddingOf(context);

    const fabSize = 56.0;
    const margin = 12.0;
    const minVisible = 18.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;

        final corner = HelperBotPlacement.cornerOf(context);
        final defaultPosition = corner == HelperBotCorner.topRight
            ? Offset(size.width - fabSize - margin, padding.top + margin)
            : Offset(margin, size.height - padding.bottom - viewInsets.bottom - fabSize - margin);

        final unclamped = _position ?? defaultPosition;
        final minX = -fabSize + minVisible;
        final maxX = size.width - minVisible;
        final minY = padding.top - fabSize + minVisible;
        final maxY = size.height - padding.bottom - viewInsets.bottom - minVisible;

        final position = Offset(
          unclamped.dx.clamp(minX, maxX),
          unclamped.dy.clamp(minY, maxY),
        );

        return Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final current = _position ?? defaultPosition;
                    final next = current + details.delta;
                    _position = Offset(
                      next.dx.clamp(minX, maxX),
                      next.dy.clamp(minY, maxY),
                    );
                  });
                },
                child: FloatingActionButton(
                  onPressed: _open,
                  child: const Icon(Icons.chat_bubble_rounded),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HelperBotSheet extends StatefulWidget {
  const _HelperBotSheet({required this.service});

  final OllamaChatService service;

  @override
  State<_HelperBotSheet> createState() => _HelperBotSheetState();
}

class _HelperBotSheetState extends State<_HelperBotSheet> {
  final _controller = TextEditingController();

  final List<OllamaMessage> _messages = [
    const OllamaMessage(
      role: 'assistant',
      content: 'Hi! Ask me a question — I run locally via Ollama.',
    ),
  ];

  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
      _messages.add(OllamaMessage(role: 'user', content: text));
      _controller.clear();
    });

    try {
      final reply = await widget.service.chat(messages: _messages);
      if (!mounted) return;
      setState(() {
        _messages.add(OllamaMessage(role: 'assistant', content: reply));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Ollama error at ${widget.service.baseUrl}: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, sheetController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Helper',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    widget.service.model,
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
             if (_error != null)
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 child: Text(
                   _error!,
                   style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                 ),
               ),
             if (_sending)
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                 child: ClipRRect(
                   borderRadius: BorderRadius.circular(999),
                   child: const LinearProgressIndicator(minHeight: 6),
                 ),
               ),
             Expanded(
               child: ListView.builder(
                 controller: sheetController,
                 padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                 itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg.role == 'user';
                  final bubbleColor = isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest;
                  final textColor = isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 520),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(msg.content, style: theme.textTheme.bodyMedium?.copyWith(color: textColor)),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Ask a question…',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
