import 'package:epub_view/epub_view.dart';
import 'package:epub_view/src/data/models/chapter.dart';
import 'package:epub_view/src/data/models/chapter_view_value.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';

import '../book_library_state.dart';
import '../models/book.dart';
import '../utils/book_reader_documents.dart';

class BookReaderScreen extends StatefulWidget {
  const BookReaderScreen({
    super.key,
    required this.bookId,
    required this.filePath,
    this.titleOverride,
  });

  final String bookId;
  final String filePath;
  final String? titleOverride;

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  late final BookFormat _format;
  late final Future<EpubBook>? _epubFuture;
  late final Future<PdfDocument>? _pdfFuture;

  EpubController? _epubController;
  PdfControllerPinch? _pdfController;

  double? _pendingPdfSliderPage;

  @override
  void initState() {
    super.initState();

    final book = context.read<BookLibraryState>().byId(widget.bookId);
    _format = book?.format ?? (widget.filePath.toLowerCase().endsWith('.pdf') ? BookFormat.pdf : BookFormat.epub);

    if (_format == BookFormat.epub) {
      _epubFuture = epubDocumentFromPath(widget.filePath);
      _pdfFuture = null;
    } else {
      _pdfFuture = pdfDocumentFromPath(widget.filePath);
      _epubFuture = null;
    }
  }

  @override
  void dispose() {
    _epubController?.dispose();
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _showEpubToc() async {
    final controller = _epubController;
    if (controller == null) {
      return;
    }

    final chapters = controller.tableOfContentsListenable.value;
    if (chapters.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            itemCount: chapters.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = chapters[index];
              final title = entry.title?.trim().isEmpty ?? true ? 'Untitled' : entry.title!.trim();
              return ListTile(
                title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.of(context).pop();
                  controller.jumpTo(index: entry.startIndex);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showPdfJumpDialog({required int pagesCount, required int currentPage}) async {
    final controller = _pdfController;
    if (controller == null) {
      return;
    }

    final pageController = TextEditingController(text: currentPage.toString());
    final target = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Go to page'),
          content: TextField(
            controller: pageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: '1-$pagesCount'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(pageController.text.trim());
                if (parsed == null) {
                  Navigator.of(context).pop();
                  return;
                }
                Navigator.of(context).pop(parsed.clamp(1, pagesCount));
              },
              child: const Text('Go'),
            ),
          ],
        );
      },
    );

    pageController.dispose();
    if (target == null) {
      return;
    }

    await controller.animateToPage(
      pageNumber: target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  Widget? _buildBottomReaderBar() {
    if (_format == BookFormat.epub) {
      final controller = _epubController;
      if (controller == null) {
        return null;
      }

      return ValueListenableBuilder<List<EpubViewChapter>>(
        valueListenable: controller.tableOfContentsListenable,
        builder: (context, toc, _) {
          return ValueListenableBuilder<EpubChapterViewValue?>(
            valueListenable: controller.currentValueListenable,
            builder: (context, value, __) {
              final total = toc.isEmpty ? null : toc.length;
              final chapterNumber = value?.chapterNumber;
              final chapterTitle = value?.chapter?.Title?.trim();
              final title = (chapterTitle == null || chapterTitle.isEmpty)
                  ? 'Chapter'
                  : chapterTitle;

              final progress = (total == null || chapterNumber == null)
                  ? null
                  : (chapterNumber / total).clamp(0.0, 1.0);

              return Material(
                elevation: 6,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          total == null || chapterNumber == null
                              ? title
                              : '$title ($chapterNumber/$total)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: progress),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    final controller = _pdfController;
    if (controller == null) {
      return null;
    }

    return ValueListenableBuilder<int>(
      valueListenable: controller.pageListenable,
      builder: (context, page, _) {
        final pagesCount = controller.pagesCount;
        if (pagesCount == null || pagesCount <= 1) {
          return const SizedBox.shrink();
        }

        final current = _pendingPdfSliderPage?.round().clamp(1, pagesCount) ?? page;

        return Material(
          elevation: 6,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(
                children: [
                  Text('Page $current/$pagesCount'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Slider(
                      min: 1,
                      max: pagesCount.toDouble(),
                      divisions: pagesCount - 1,
                      value: current.toDouble(),
                      onChanged: (value) {
                        setState(() {
                          _pendingPdfSliderPage = value;
                        });
                      },
                      onChangeEnd: (value) async {
                        setState(() {
                          _pendingPdfSliderPage = null;
                        });
                        await controller.animateToPage(
                          pageNumber: value.round(),
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = context.watch<BookLibraryState>().byId(widget.bookId);
    final title = widget.titleOverride ?? book?.title ?? 'Reader';

    final bottomBar = _buildBottomReaderBar();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_format == BookFormat.epub)
            IconButton(
              tooltip: 'Chapters',
              icon: const Icon(Icons.list_alt),
              onPressed: _showEpubToc,
            ),
          if (_format == BookFormat.pdf)
            if (_pdfController == null)
              IconButton(
                tooltip: 'Go to page',
                icon: const Icon(Icons.find_in_page_outlined),
                onPressed: null,
              )
            else
              ValueListenableBuilder<int>(
                valueListenable: _pdfController!.pageListenable,
                builder: (context, page, _) {
                  final pagesCount = _pdfController!.pagesCount;
                  return IconButton(
                    tooltip: 'Go to page',
                    icon: const Icon(Icons.find_in_page_outlined),
                    onPressed: pagesCount == null
                        ? null
                        : () => _showPdfJumpDialog(pagesCount: pagesCount, currentPage: page),
                  );
                },
              ),
        ],
      ),
      bottomNavigationBar: bottomBar,
      body: _format == BookFormat.epub
          ? FutureBuilder<EpubBook>(
              future: _epubFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data;
                if (data == null) {
                  return _ReaderErrorView(
                    error: snapshot.error,
                    filePath: widget.filePath,
                  );
                }

                _epubController ??= EpubController(document: Future.value(data));
                return EpubView(
                  controller: _epubController!,
                  onDocumentLoaded: (_) => context.read<BookLibraryState>().markOpened(bookId: widget.bookId),
                );
              },
            )
          : FutureBuilder<PdfDocument>(
              future: _pdfFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data;
                if (data == null) {
                  return _ReaderErrorView(
                    error: snapshot.error,
                    filePath: widget.filePath,
                  );
                }

                _pdfController ??= PdfControllerPinch(document: Future.value(data));
                return PdfViewPinch(
                  controller: _pdfController!,
                  onDocumentLoaded: (_) => context.read<BookLibraryState>().markOpened(bookId: widget.bookId),
                  onPageChanged: (_) {
                    if (_pendingPdfSliderPage != null) {
                      setState(() {
                        _pendingPdfSliderPage = null;
                      });
                    }
                  },
                );
              },
            ),
    );
  }
}

class _ReaderErrorView extends StatelessWidget {
  const _ReaderErrorView({required this.error, required this.filePath});

  final Object? error;
  final String filePath;

  @override
  Widget build(BuildContext context) {
    final isHttp = filePath.startsWith('http://') || filePath.startsWith('https://');
    final message = error == null ? 'Failed to open this book.' : error.toString();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Couldn\'t open this book',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              if (kIsWeb && isHttp)
                FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Back'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
