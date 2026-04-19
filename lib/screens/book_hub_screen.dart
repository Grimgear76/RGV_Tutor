import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../book_library_state.dart';
import '../models/book.dart';
import '../widgets/library_mode_toggle.dart';
import '../widgets/local_file_image.dart';
import '../widgets/network_image.dart';
import 'book_reader_screen.dart';

class BookHubScreen extends StatefulWidget {
  const BookHubScreen({super.key});

  @override
  State<BookHubScreen> createState() => _BookHubScreenState();
}

class _BookHubScreenState extends State<BookHubScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BookLibraryState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: const LibraryModeToggle(compact: true),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: index,
        children: const [
          _CatalogTab(),
          _LibraryTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (next) => setState(() => index = next),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.public_rounded), label: 'Catalog'),
          NavigationDestination(icon: Icon(Icons.library_books_rounded), label: 'My Library'),
        ],
      ),
    );
  }
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BookLibraryState>();
    final catalog = state.catalog;

    return _SearchableBookList(
      items: catalog,
      emptyLabel: 'No books found.',
      builder: (context, book) {
        final existing = state.byId(book.id);
        final isInLibrary = existing != null;
        final isDownloaded = existing?.isDownloaded ?? false;

        return _BookCard(
          book: existing ?? book,
          trailing: Wrap(
            spacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: state.isOnline
                    ? () async {
                        final path = await state.prepareOnlineReadEntry(book);
                        if (path == null) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not prepare this book for reading. Try downloading it.',
                              ),
                            ),
                          );
                          return;
                        }
                        if (!context.mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookReaderScreen(bookId: book.id, filePath: path, titleOverride: book.title),
                          ),
                        );
                      }
                    : null,
                child: const Text('Read'),
              ),
              FilledButton(
                onPressed: isDownloaded
                    ? null
                    : () async {
                        await state.addFromCatalog(book);

                        if (!state.isOnline) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to your library. Connect to the internet to download.')),
                          );
                          return;
                        }

                        if (kIsWeb) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to your library. Downloads are not supported on web yet.')),
                          );
                          return;
                        }

                        await state.download(book.id);
                      },
                child: Text(
                  isDownloaded
                      ? 'Downloaded'
                      : isInLibrary
                          ? (state.isOnline && !kIsWeb ? 'Download' : 'Added')
                          : (state.isOnline && !kIsWeb ? 'Add & download' : 'Add'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LibraryTab extends StatelessWidget {
  const _LibraryTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BookLibraryState>();
    final items = state.library;

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No books in your library yet.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      );
    }

    return _SearchableBookList(
      items: items,
      emptyLabel: 'No books found.',
      builder: (context, book) {
        final canOpen = (book.isDownloaded && book.localPath != null) || (kIsWeb && state.isOnline);
        final canDownload = state.isOnline && !kIsWeb && !book.isDownloaded;

        return _BookCard(
          book: book,
          trailing: Wrap(
            spacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: !canOpen
                    ? null
                    : () async {
                        final path = kIsWeb ? book.resolvedRemoteUrl : book.localPath;
                        if (path == null) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => BookReaderScreen(bookId: book.id, filePath: path)),
                        );
                      },
                child: const Text('Open'),
              ),
              FilledButton(
                onPressed: !canDownload ? null : () => state.download(book.id),
                child: Text(book.downloadState == BookDownloadState.failed ? 'Retry' : 'Download'),
              ),
              IconButton.filledTonal(
                tooltip: 'Remove',
                onPressed: () => state.remove(book.id),
                icon: const Icon(Icons.delete_rounded),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.trailing});

  final BookEntry book;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final cover = _buildCover(colorScheme);
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900);
    final authorStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: titleStyle),
        const SizedBox(height: 4),
        Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: authorStyle),
        const SizedBox(height: 8),
        if (book.downloadState == BookDownloadState.downloading) ...[
          LinearProgressIndicator(value: book.downloadProgress),
          const SizedBox(height: 8),
        ],
        if (book.downloadState == BookDownloadState.failed && (book.error?.isNotEmpty ?? false))
          Text(book.error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.error)),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 520;

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      cover,
                      const SizedBox(width: 12),
                      Expanded(child: details),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: trailing,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cover,
                const SizedBox(width: 12),
                Expanded(child: details),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Align(alignment: Alignment.topRight, child: trailing),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCover(ColorScheme colorScheme) {
    final localCoverPath = book.localCoverPath;
    if (!kIsWeb && localCoverPath != null && localCoverPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: localFileImage(
          localCoverPath,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _coverFallback(colorScheme),
        ),
      );
    }

    final url = book.coverUrl;
    if (url == null || url.isEmpty) return _coverFallback(colorScheme);

    return NetworkImageView(
      url: url,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(14),
      fallback: _coverFallback(colorScheme),
    );
  }

  Widget _coverFallback(ColorScheme colorScheme) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.menu_book_rounded, color: colorScheme.onSurfaceVariant),
    );
  }
}

class _SearchableBookList extends StatefulWidget {
  const _SearchableBookList({required this.items, required this.emptyLabel, required this.builder});

  final List<BookEntry> items;
  final String emptyLabel;
  final Widget Function(BuildContext context, BookEntry book) builder;

  @override
  State<_SearchableBookList> createState() => _SearchableBookListState();
}

class _SearchableBookListState extends State<_SearchableBookList> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.items
        : widget.items
            .where((b) =>
                b.title.toLowerCase().contains(q) ||
                b.author.toLowerCase().contains(q) ||
                b.source.id.toLowerCase().contains(q))
            .toList(growable: false);

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search by title or author',
              ),
              onChanged: (v) => setState(() => query = v),
            ),
            const SizedBox(height: 24),
            Text(
              widget.emptyLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i == 0) {
          return TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search by title or author',
            ),
            onChanged: (v) => setState(() => query = v),
          );
        }
        return widget.builder(context, filtered[i - 1]);
      },
    );
  }
}
