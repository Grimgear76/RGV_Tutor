import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app_state.dart';

class SubjectShareScreen extends StatelessWidget {
  const SubjectShareScreen({super.key, required this.categoryId, required this.categoryName});

  final String categoryId;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final data = state.exportCategoryPack(categoryId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share subject'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                categoryName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Have someone scan this QR code to import a copy.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: QrImageView(
                      data: data,
                      version: QrVersions.auto,
                      size: 280,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
