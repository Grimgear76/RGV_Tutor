import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

class SubjectImportScreen extends StatefulWidget {
  const SubjectImportScreen({super.key});

  @override
  State<SubjectImportScreen> createState() => _SubjectImportScreenState();
}

class _SubjectImportScreenState extends State<SubjectImportScreen> {
  late final MobileScannerController _controller;
  bool _importing = false;
  bool _triedAnyCameraFallback = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      autoStart: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import subject'),
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, _) {
              final available = state.availableCameras;
              final showSwitch = (available ?? 0) > 1;
              return IconButton(
                tooltip: 'Switch camera',
                onPressed: showSwitch ? () => _controller.switchCamera() : null,
                icon: const Icon(Icons.cameraswitch_rounded),
              );
            },
          ),
          IconButton(
            tooltip: 'Paste code',
            onPressed: _importing ? null : () => _showPasteDialog(context),
            icon: const Icon(Icons.content_paste_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  if (_importing) return;
                  final value = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
                  if (value == null) return;
                  _attemptImport(value);
                },
                errorBuilder: (context, error, child) {
                  if (!_triedAnyCameraFallback && error.errorCode == MobileScannerErrorCode.genericError) {
                    _triedAnyCameraFallback = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _controller.start(cameraDirection: CameraFacing.front);
                    });
                  }

                  return ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_rounded, color: Colors.white.withOpacity(0.9), size: 42),
                            const SizedBox(height: 10),
                            Text(
                              'Camera unavailable',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try switching cameras or paste an import code.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.white70, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: (_controller.value.availableCameras ?? 0) > 1 ? () => _controller.switchCamera() : null,
                                  icon: const Icon(Icons.cameraswitch_rounded),
                                  label: const Text('Switch'),
                                ),
                                const SizedBox(width: 10),
                                FilledButton.icon(
                                  onPressed: _importing ? null : () => _showPasteDialog(context),
                                  icon: const Icon(Icons.content_paste_rounded),
                                  label: const Text('Paste'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                overlayBuilder: (context, constraints) {
                  final size = constraints.biggest;
                  final rect = Rect.fromCenter(
                    center: size.center(Offset.zero),
                    width: size.width * 0.72,
                    height: size.width * 0.72,
                  );
                  return CustomPaint(
                    painter: _ScannerOverlayPainter(rect: rect),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'Scan a subject QR code to import.',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _attemptImport(String data) async {
    setState(() => _importing = true);
    final state = context.read<AppState>();

    final id = state.importCategoryPack(data);
    if (!mounted) return;

    if (id == null) {
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid import code.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subject imported.')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _showPasteDialog(BuildContext context) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Paste import code'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(context).pop(value),
            decoration: const InputDecoration(hintText: 'RGVTUTOR1:…'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Import')),
          ],
        );
      },
    );

    if (value == null) return;
    if (!mounted) return;
    _attemptImport(value);
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter({required this.rect});

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());

    final overlayPaint = Paint()..color = const Color(0xAA000000);
    canvas.drawRect(Offset.zero & size, overlayPaint);

    final cutoutPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectXY(rect, 18, 18), cutoutPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(RRect.fromRectXY(rect, 18, 18), borderPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) => oldDelegate.rect != rect;
}
