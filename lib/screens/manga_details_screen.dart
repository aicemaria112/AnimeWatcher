import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
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
  Map<String, double> _downloadProgress = {}; // Track download progress for each chapter
  
  // Pagination variables
  int _offset = 0;
  final int _limit = 100;
  bool _hasMoreChapters = true;
  List<Chapter> _chapters = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _mangaDetail = _loadInitialData();
    _checkBookmarkStatus();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  

  
  Future<MangaDetail> _loadInitialData() async {
    final mangaDetail = await _mangaService.getMangaDetails(widget.manga.mangaUrl, offset: _offset, limit: _limit);
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
        limit: _limit
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
    final isBookmarked = await _storageService.isBookmarked(widget.manga.mangaUrl);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  manga.mangaImagen,
                  width: 120,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manga.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(manga.score),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Status: ${manga.status}'),
                    const SizedBox(height: 8),
                    if (manga.authors.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Authors: ${manga.authors.join(', ')}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Genres moved below the image and above description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Genres:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: manga.genres.map((genre) => Chip(
                  label: Text(
                    genre,
                    style: const TextStyle(fontSize: 11),
                  ),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  padding: EdgeInsets.zero,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Description',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(manga.description),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manga Details'),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked ? Colors.amber : null,
                  ),
                  onPressed: _toggleBookmark,
                  tooltip: _isBookmarked ? 'Remove from bookmarks' : 'Add to bookmarks',
                ),
        ],
      ),
      body: FutureBuilder<MangaDetail>(
        future: _mangaDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final manga = snapshot.data!;
          return NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 500 &&
                  !_isLoadingMore &&
                  _hasMoreChapters) {
                _loadMoreChapters();
              }
              return false;
            },
            child: CustomScrollView(
              cacheExtent: 500,
              slivers: [
                SliverToBoxAdapter(
                  child: _buildInfoSection(manga),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chapters',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${_chapters.length}/${manga.totalChapters}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _chapters.length && _hasMoreChapters) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      final chapter = _chapters[index];
                      return FutureBuilder<bool>(
                        future: _storageService.isChapterDownloaded(manga.title, chapter.title),
                        builder: (context, snapshot) {
                          final bool isDownloaded = snapshot.data ?? false;
                          
                          return ListTile(
                            title: Text('${chapter.title} (${index + 1}/${manga.totalChapters})'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isDownloaded)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                  )
                                else
                                  IconButton(
                                    icon: _downloadProgress.containsKey(chapter.urlLeer) && _downloadProgress[chapter.urlLeer]! > 0 && _downloadProgress[chapter.urlLeer]! < 1
                                      ? Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                value: _downloadProgress[chapter.urlLeer],
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            Text(
                                              '${(_downloadProgress[chapter.urlLeer]! * 100).toInt()}%',
                                              style: const TextStyle(fontSize: 8),
                                            ),
                                          ],
                                        )
                                      : const Icon(Icons.download_for_offline_outlined),
                                    onPressed: _downloadProgress.containsKey(chapter.urlLeer) && _downloadProgress[chapter.urlLeer]! > 0 && _downloadProgress[chapter.urlLeer]! < 1
                                      ? null
                                      : () async {
                                        // Implement chapter download
                                        setState(() {
                                          _isLoading = true;
                                          _downloadProgress[chapter.urlLeer] = 0.0;
                                        });
                                        try {
                                          // Get chapter images
                                          final pages = await _mangaService.getChapterImages(chapter.urlLeer);
                                          
                                          // Download chapter
                                          final chapterDir = await _storageService.getChapterDownloadPath(manga.title, chapter.title);
                                          
                                          // Download images with progress tracking
                                          for (var i = 0; i < pages.length; i++) {
                                            final file = await DefaultCacheManager().getSingleFile(pages[i]);
                                            final newPath = '$chapterDir/page_${i + 1}.jpg';
                                            await file.copy(newPath);
                                            
                                            // Update progress after each file is downloaded
                                            if (mounted) {
                                              setState(() {
                                                _downloadProgress[chapter.urlLeer] = (i + 1) / pages.length;
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
                                                  return pw.Center(
                                                    child: pw.Image(image),
                                                  );
                                                },
                                              ),
                                            );
                                          }
                                          await pdf.save().then((bytes) => File('$chapterDir/${chapter.title}.pdf').writeAsBytes(bytes));

                                          // Add bookmark for this manga
                                          await _storageService.addBookmark(widget.manga.mangaUrl);
                                          
                                          // Save as last viewed chapter
                                          await _storageService.saveLastViewedChapter(
                                            widget.manga.mangaUrl,
                                            chapter.title,
                                            chapter.urlLeer
                                          );
                                          
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Chapter downloaded successfully')),
                                          );
                                          
                                          // Refresh UI
                                          setState(() {
                                            _downloadProgress.remove(chapter.urlLeer);
                                          });
                                        } catch (e) {
                                          if (mounted) {
                                            setState(() {
                                              _downloadProgress.remove(chapter.urlLeer);
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error downloading chapter: $e')),
                                            );
                                          }
                                        } finally {
                                          setState(() => _isLoading = false);
                                        }
                                      },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MangaReaderScreen(
                                          chapter: chapter,
                                          mangaUrl: widget.manga.mangaUrl,
                                        ),
                                      ),
                                    ).then((_) => setState(() {}));
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    childCount: _chapters.length + (_hasMoreChapters ? 1 : 0),
                  ),
                ),
                // if (_isLoadingMore && _chapters.isNotEmpty)
                //   const SliverToBoxAdapter(
                //     child: Padding(
                //       padding: EdgeInsets.all(8.0),
                //       child: Center(child: CircularProgressIndicator()),
                //     ),
                //   ),
              ],
            ),
          );
        },
      ),
    );
  }
}