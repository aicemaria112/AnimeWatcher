import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'dart:ui';
import '../models/manga.dart';
import '../services/manga_service.dart';
import '../services/storage_service.dart';
import '../screens/manga_reader_screen.dart';
import 'dart:developer';

class MangaDetailsScreen extends StatefulWidget {
  final Manga manga;

  const MangaDetailsScreen({super.key, required this.manga});

  @override
  State<MangaDetailsScreen> createState() => _MangaDetailsScreenState();
}

class _MangaDetailsScreenState extends State<MangaDetailsScreen> {
  final MangaService _mangaService = MangaService();
  final StorageService _storageService = StorageService();
  late Future<MangaDetail> _mangaDetail;
  bool _isBookmarked = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  Map<String, double> _downloadProgress = {};

  // Pagination variables
  int _offset = 0;
  final int _limit = 100;
  bool _hasMoreChapters = true;
  List<Chapter> _chapters = [];
  final ScrollController _scrollController = ScrollController();

  // Description expansion state
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _mangaDetail = _loadInitialData();
    _checkBookmarkStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Helper method to get color based on manga status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'hiatus':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get color based on genre
  Color _getGenreColor(String genre) {
    final Map<String, Color> genreColors = {
      'action': Colors.red,
      'adventure': Colors.orange,
      'comedy': Colors.yellow,
      'drama': Colors.purple,
      'fantasy': Colors.blue,
      'horror': Colors.deepPurple,
      'mystery': Colors.indigo,
      'romance': Colors.pink,
      'sci-fi': Colors.teal,
      'slice of life': Colors.lightGreen,
      'sports': Colors.green,
      'supernatural': Colors.amber,
      'thriller': Colors.deepOrange,
    };

    return genreColors[genre.toLowerCase()] ?? Theme.of(context).primaryColor;
  }

  Future<MangaDetail> _loadInitialData() async {
    final mangaDetail = await _mangaService.getMangaDetails(
      widget.manga.mangaUrl,
      offset: _offset,
      limit: _limit,
    );
    log(mangaDetail.authors.toString());
    setState(() {
      _chapters = mangaDetail.chapters;
      _hasMoreChapters = mangaDetail.hasMoreChapters;
      _offset += _limit;
    });
    return mangaDetail;
  }

  Future<void> _loadMoreChapters() async {
    if (!_hasMoreChapters || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final mangaDetail = await _mangaService.getMangaDetails(
        widget.manga.mangaUrl,
        offset: _offset,
        limit: _limit,
      );

      setState(() {
        _chapters.addAll(mangaDetail.chapters);
        _hasMoreChapters = mangaDetail.hasMoreChapters;
        _offset += _limit;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar más capítulos: $e')),
      );
    }
  }

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked = await _storageService.isBookmarked(
      widget.manga.mangaUrl,
    );
    setState(() {
      _isBookmarked = isBookmarked;
    });
  }

  Future<void> _toggleBookmark() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isBookmarked) {
        await _storageService.removeBookmark(widget.manga.mangaUrl);
      } else {
        await _storageService.addBookmark(widget.manga.mangaUrl);
      }

      setState(() {
        _isBookmarked = !_isBookmarked;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoSection(MangaDetail manga) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0),
                Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Manga Cover with shadow and border
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    manga.mangaImagen,
                    width: 130,
                    height: 190,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 130,
                        height: 190,
                        color: Colors.grey[800],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 130,
                        height: 190,
                        color: Colors.grey[800],
                        child: const Icon(Icons.broken_image, size: 40),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manga.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            manga.score,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(manga.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Status: ${manga.status}',
                        style: TextStyle(
                          color: _getStatusColor(manga.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (manga.authors.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Authors:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[300],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            manga.authors.join(', '),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Genres section with improved design
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.category, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Genres',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 30, // Fixed height for the scrolling row
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      manga.genres
                          .map(
                            (genre) => Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getGenreColor(
                                    genre,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _getGenreColor(
                                      genre,
                                    ).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  genre,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getGenreColor(genre),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Icon(Icons.description, size: 20),
              const SizedBox(width: 8),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color?.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      manga.description,
                      maxLines: _isDescriptionExpanded ? null : 3,
                      overflow:
                          _isDescriptionExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isDescriptionExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isDescriptionExpanded
                                  ? 'Mostrar Menos'
                                  : 'Mostrar Todo',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Refresh manga details
  Future<void> _refreshData() async {
    setState(() {
      _offset = 0;
      _chapters = [];
      _hasMoreChapters = true;
      _mangaDetail = _loadInitialData();
    });
    await _checkBookmarkStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manga Details',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        elevation: 4,
        actions: [
          _isLoading
              ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
              : IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: _isBookmarked ? Colors.amber : Colors.white,
                  size: 28,
                ),
                onPressed: _toggleBookmark,
                tooltip:
                    _isBookmarked
                        ? 'Remove from bookmarks'
                        : 'Add to bookmarks',
              ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Theme.of(context).primaryColor,
        backgroundColor: Colors.white,
        child: FutureBuilder<MangaDetail>(
          future: _mangaDetail,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No data available'));
            }

            final manga = snapshot.data!;
            return NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent - 500 &&
                    !_isLoadingMore &&
                    _hasMoreChapters) {
                  _loadMoreChapters();
                }
                return false;
              },
              child: CustomScrollView(
                cacheExtent: 500,
                slivers: [
                  SliverToBoxAdapter(child: _buildInfoSection(manga)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.menu_book, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Chapters',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_chapters.length}/${manga.totalChapters}',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index == _chapters.length && _hasMoreChapters) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final chapter = _chapters[index];
                      return FutureBuilder<bool>(
                        future: _storageService.isChapterDownloaded(
                          manga.title,
                          chapter.title,
                        ),
                        builder: (context, snapshot) {
                          final bool isDownloaded = snapshot.data ?? false;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 3,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              title: Text(
                                '${chapter.title}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                'Chapter ${manga.totalChapters-index} of ${manga.totalChapters}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isDownloaded)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Downloaded',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    IconButton(
                                      icon:
                                          _downloadProgress.containsKey(
                                                    chapter.urlLeer,
                                                  ) &&
                                                  _downloadProgress[chapter
                                                          .urlLeer]! >
                                                      0 &&
                                                  _downloadProgress[chapter
                                                          .urlLeer]! <
                                                      1
                                              ? Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      value:
                                                          _downloadProgress[chapter
                                                              .urlLeer],
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${(_downloadProgress[chapter.urlLeer]! * 100).toInt()}%',
                                                    style: const TextStyle(
                                                      fontSize: 8,
                                                    ),
                                                  ),
                                                ],
                                              )
                                              : const Icon(
                                                Icons
                                                    .download_for_offline_outlined,
                                              ),
                                      onPressed:
                                          _downloadProgress.containsKey(
                                                    chapter.urlLeer,
                                                  ) &&
                                                  _downloadProgress[chapter
                                                          .urlLeer]! >
                                                      0 &&
                                                  _downloadProgress[chapter
                                                          .urlLeer]! <
                                                      1
                                              ? null
                                              : () async {
                                                // Implement chapter download
                                                setState(() {
                                                  _isLoading = true;
                                                  _downloadProgress[chapter
                                                          .urlLeer] =
                                                      0.0;
                                                });
                                                try {
                                                  // Get chapter images
                                                  final pages =
                                                      await _mangaService
                                                          .getChapterImages(
                                                            chapter.urlLeer,
                                                          );

                                                  // Download chapter
                                                  final chapterDir =
                                                      await _storageService
                                                          .getChapterDownloadPath(
                                                            manga.title,
                                                            chapter.title,
                                                          );

                                                  // Download images with progress tracking
                                                  for (
                                                    var i = 0;
                                                    i < pages.length;
                                                    i++
                                                  ) {
                                                    final file =
                                                        await DefaultCacheManager()
                                                            .getSingleFile(
                                                              pages[i],
                                                            );
                                                    final newPath =
                                                        '$chapterDir/page_${i + 1}.jpg';
                                                    await file.copy(newPath);

                                                    // Update progress after each file is downloaded
                                                    if (mounted) {
                                                      setState(() {
                                                        _downloadProgress[chapter
                                                                .urlLeer] =
                                                            (i + 1) /
                                                            pages.length;
                                                      });
                                                    }
                                                  }

                                                  // Create PDF
                                                  final pdf = pw.Document();
                                                  for (
                                                    var i = 0;
                                                    i < pages.length;
                                                    i++
                                                  ) {
                                                    final file = File(
                                                      '$chapterDir/page_${i + 1}.jpg',
                                                    );
                                                    final imageBytes =
                                                        await file
                                                            .readAsBytes();
                                                    final image =
                                                        pw.MemoryImage(
                                                          imageBytes,
                                                        );
                                                    
                                                    // Decodificar la imagen para obtener sus dimensiones
                                                    final decodedImage = await decodeImageFromList(imageBytes);
                                                    final width = decodedImage.width.toDouble();
                                                    final height = decodedImage.height.toDouble();
                                                    
                                                    // Crear un formato de página personalizado basado en las dimensiones de la imagen
                                                    final pageFormat = PdfPageFormat(width, height);
                                                    
                                                    pdf.addPage(
                                                      pw.Page(
                                                        pageFormat: pageFormat,
                                                        build: (context) {
                                                          // Usar la imagen sin centrarla para que ocupe toda la página
                                                          return pw.Image(
                                                            image,
                                                            fit: pw.BoxFit.fill,
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  }
                                                  await pdf.save().then(
                                                    (bytes) => File(
                                                      '$chapterDir/${chapter.title}.pdf',
                                                    ).writeAsBytes(bytes),
                                                  );

                                                  // Add bookmark for this manga
                                                  await _storageService
                                                      .addBookmark(
                                                        widget.manga.mangaUrl,
                                                      );

                                                  // Save as last viewed chapter
                                                  await _storageService
                                                      .saveLastViewedChapter(
                                                        widget.manga.mangaUrl,
                                                        chapter.title,
                                                        chapter.urlLeer,
                                                      );

                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Chapter downloaded successfully',
                                                      ),
                                                    ),
                                                  );

                                                  // Refresh UI
                                                  setState(() {
                                                    _downloadProgress.remove(
                                                      chapter.urlLeer,
                                                    );
                                                  });
                                                } catch (e) {
                                                  if (mounted) {
                                                    setState(() {
                                                      _downloadProgress.remove(
                                                        chapter.urlLeer,
                                                      );
                                                    });
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Error downloading chapter: $e',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                } finally {
                                                  setState(
                                                    () => _isLoading = false,
                                                  );
                                                }
                                              },
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => MangaReaderScreen(
                                                chapter: chapter,
                                                mangaUrl: widget.manga.mangaUrl,
                                              ),
                                        ),
                                      ).then((_) => setState(() {}));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }, childCount: _chapters.length + (_hasMoreChapters ? 1 : 0)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
