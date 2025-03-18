import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import '../models/manga.dart';
import '../services/manga_service.dart';
import '../services/storage_service.dart';

class MangaReaderScreen extends StatefulWidget {
  final Chapter chapter;
  final String mangaUrl;

  const MangaReaderScreen({
    super.key,
    required this.chapter,
    required this.mangaUrl,
  });

  @override
  State<MangaReaderScreen> createState() => _MangaReaderScreenState();
}

class _MangaReaderScreenState extends State<MangaReaderScreen> {
  final MangaService _mangaService = MangaService();
  final StorageService _storageService = StorageService();
  late Future<List<String>> _pagesFuture;
  PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  bool _isLoading = false;
  bool get _isAnyZoomed => _isZoomed.values.any((zoomed) => zoomed);
  double _downloadProgress = 0.0; // Track download progress percentage
  Offset _tapPosition = Offset.zero;
  // Variables para el control de zoom con doble tap
  final Map<int, TransformationController> _transformationControllers = {};
  final Map<int, bool> _isZoomed = {};

  @override
  void initState() {
    super.initState();
    _pagesFuture = _getChapterImages();
    _loadSavedPage();
    _checkDownloadStatus();
    _saveLastViewedChapter();
  }

  Future<List<String>> _getChapterImages() async {
    // Get manga title from the manga service
    final mangaDetail = await _mangaService.getMangaDetails(widget.mangaUrl);

    // Check if the chapter is downloaded
    final isDownloaded = await _storageService.isChapterDownloaded(
      mangaDetail.title,
      widget.chapter.title,
    );

    if (isDownloaded) {
      // If downloaded, get local image paths
      return _getLocalImagePaths();
    } else {
      // If not downloaded, fetch from network
      return _mangaService.getChapterImages(widget.chapter.urlLeer);
    }
  }

  Future<List<String>> _getLocalImagePaths() async {
    // Get manga title from the manga service
    final mangaDetail = await _mangaService.getMangaDetails(widget.mangaUrl);
    final chapterDir = await _storageService.getChapterDownloadPath(
      mangaDetail.title,
      widget.chapter.title,
    );
    final directory = Directory(chapterDir);
    final List<String> imagePaths = [];

    // Get all jpg files in the directory
    final List<FileSystemEntity> files = await directory.list().toList();
    for (var file in files) {
      if (file.path.endsWith('.jpg')) {
        imagePaths.add(file.path);
      }
    }

    // Sort the images by page number
    imagePaths.sort((a, b) {
      final aMatch = RegExp(r'page_([0-9]+)\.jpg').firstMatch(a);
      final bMatch = RegExp(r'page_([0-9]+)\.jpg').firstMatch(b);
      if (aMatch != null && bMatch != null) {
        return int.parse(
          aMatch.group(1)!,
        ).compareTo(int.parse(bMatch.group(1)!));
      }
      return a.compareTo(b);
    });

    return imagePaths;
  }

  bool _isDownloaded = false;

  Future<void> _checkDownloadStatus() async {
    // Get manga title from the manga service
    final mangaDetail = await _mangaService.getMangaDetails(widget.mangaUrl);

    final isDownloaded = await _storageService.isChapterDownloaded(
      mangaDetail.title,
      widget.chapter.title,
    );
    setState(() {
      _isDownloaded = isDownloaded;
    });
  }

  Future<void> _loadSavedPage() async {
    final savedPage = await _storageService.getReadingProgress(
      widget.mangaUrl,
      widget.chapter.urlLeer,
    );
    setState(() {
      _currentPage = savedPage;
    });

    // Use addPostFrameCallback to ensure the PageController is attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pageController.jumpToPage(savedPage);
      }
    });
  }

  Future<void> _savePage(int page) async {
    await _storageService.saveReadingProgress(
      widget.mangaUrl,
      widget.chapter.urlLeer,
      page,
    );
  }

  Future<void> _saveLastViewedChapter() async {
    await _storageService.saveLastViewedChapter(
      widget.mangaUrl,
      widget.chapter.title,
      widget.chapter.urlLeer,
    );
  }

  Future<void> _downloadChapter(List<String> pages) async {
    setState(() {
      _isLoading = true;
      _downloadProgress = 0.0;
    });
    try {
      // Get manga title from the manga service
      final mangaDetail = await _mangaService.getMangaDetails(widget.mangaUrl);
      final chapterDir = await _storageService.getChapterDownloadPath(
        mangaDetail.title,
        widget.chapter.title,
      );

      // Download images with progress tracking
      for (var i = 0; i < pages.length; i++) {
        final file = await DefaultCacheManager().getSingleFile(pages[i]);
        final newPath = '$chapterDir/page_${i + 1}.jpg';
        await file.copy(newPath);

        // Update progress after each file is downloaded
        if (mounted) {
          setState(() {
            _downloadProgress = (i + 1) / pages.length;
          });
        }
      }

      // Create PDF
      final pdf = pw.Document();
      for (var i = 0; i < pages.length; i++) {
        final file = File('$chapterDir/page_${i + 1}.jpg');
        final imageBytes = await file.readAsBytes();
        final image = pw.MemoryImage(imageBytes);
        pdf.addPage(
          pw.Page(
            build: (context) {
              return pw.Center(child: pw.Image(image));
            },
          ),
        );
      }
      await pdf.save().then(
        (bytes) =>
            File('$chapterDir/${widget.chapter.title}.pdf').writeAsBytes(bytes),
      );

      // Update download status
      setState(() {
        _isDownloaded = true;
        _downloadProgress = 1.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chapter downloaded successfully')),
        );
      }

      // Add bookmark for this manga
      await _storageService.addBookmark(widget.mangaUrl);
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading chapter: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapter.title),
        actions: [
          FutureBuilder<List<String>>(
            future: _pagesFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              if (_isDownloaded) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      const Text('Downloaded', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }

              return _isLoading
                  ? Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                value: _downloadProgress,
                                strokeWidth: 2,
                              ),
                            ),
                            Text(
                              '${(_downloadProgress * 100).toInt()}%',
                              style: const TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                  : IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadChapter(snapshot.data!),
                  );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _pagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pages available'));
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                physics: _isAnyZoomed ? NeverScrollableScrollPhysics() : null, // Block page changes when zoomed
                itemCount: snapshot.data!.length,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                  _savePage(page);
                },
                itemBuilder: (context, index) {
                  final imagePath = snapshot.data![index];
                  final isLocalFile =
                      imagePath.contains(':\\') || imagePath.startsWith('/');

                  // Inicializar el controlador de transformación para esta página si no existe
                  if (!_transformationControllers.containsKey(index)) {
                    _transformationControllers[index] =
                        TransformationController();
                    _isZoomed[index] = false;
                  }

                  return GestureDetector(
                    onDoubleTapDown: (details) => _tapPosition = details.localPosition,
                    onDoubleTap: () {
                      setState(() {
                        if (_isZoomed[index] == true) {
                          // Volver al tamaño original
                          _transformationControllers[index]!.value =
                              Matrix4.identity();
                          _isZoomed[index] = false;
                        } else {
                          // Hacer zoom al doble del tamaño
                          final Matrix4 newMatrix =
                              Matrix4.identity()
                                ..translate(-_tapPosition.dx, -_tapPosition.dy)
                                ..scale(2.0, 2.0); // Escalar al doble
                          _transformationControllers[index]!.value = newMatrix;
                          _isZoomed[index] = true;
                        }
                      });
                    },
                    child: InteractiveViewer(
                      transformationController:
                          _transformationControllers[index],
                      minScale: 1.0,
                      panEnabled: _isZoomed[index] ?? false,
                      maxScale: 5.0,
                      boundaryMargin: EdgeInsets.all(double.infinity),
                      clipBehavior: Clip.none,
                      onInteractionEnd: (details) {
                        final currentScale =
                            _transformationControllers[index]!.value
                                .getMaxScaleOnAxis();
                        setState(() {
                          _isZoomed[index] = currentScale > 1.0;
                        });
                      },
                      child:
                          isLocalFile
                              ? Image.file(File(imagePath), fit: BoxFit.contain)
                              : Image.network(
                                imagePath,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          progress.expectedTotalBytes != null
                                              ? progress.cumulativeBytesLoaded /
                                                  progress.expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                              ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Page ${_currentPage + 1}/${snapshot.data!.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Dispose de todos los controladores de transformación
    for (var controller in _transformationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
