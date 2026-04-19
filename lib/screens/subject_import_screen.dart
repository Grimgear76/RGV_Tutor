import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'personal_questions_screen.dart';

class SubjectImportScreen extends StatefulWidget {
  const SubjectImportScreen({super.key});

  @override
  State<SubjectImportScreen> createState() => _SubjectImportScreenState();
}

class _SubjectImportScreenState extends State<SubjectImportScreen> {
  bool _imported = false;
  late final MobileScannerController _controller;
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(autoStart: false);
    if (!_isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.start();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _isDesktop {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows || TargetPlatform.linux || TargetPlatform.macOS => true,
      _ => false,
    };
  }

  void _tryImportFromText(BuildContext context) {
    if (_imported) return;
    final raw = _codeController.text.trim();
    if (raw.isEmpty) return;

    final state = context.read<AppState>();
    final id = state.importCategoryPack(raw);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid subject code.')),
      );
      return;
    }

    setState(() {
      _imported = true;
    });

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PersonalCategoryScreen(categoryId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Import subject'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text(
                  'Camera scanning is not supported on desktop. Paste the subject code to import it.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      labelText: 'Subject code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _tryImportFromText(context),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Import'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import subject'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: MobileScanner(
                controller: _controller,
                errorBuilder: (context, error, child) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'Camera unavailable.\n\n${error.errorDetails?.message ?? error.errorCode.name}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
                onDetect: (capture) {
                  if (_imported) return;
                  final barcodes = capture.barcodes;
                  if (barcodes.isEmpty) return;
                  final raw = barcodes.first.rawValue;
                  if (raw == null || raw.trim().isEmpty) return;

                  final state = context.read<AppState>();
                  final id = state.importCategoryPack(raw);
                  if (id == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid subject code.')),
                    );
                    return;
                  }

                  setState(() {
                    _imported = true;
                  });

                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => PersonalCategoryScreen(categoryId: id)),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(
                    'Scan a QR code shared by someone to add a subject offline.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
