import 'package:flutter/material.dart';
import '../models/manga.dart';
import '../services/manga_service.dart';
import '../services/storage_service.dart';
import '../screens/manga_details_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final MangaService _mangaService = MangaService();
  final StorageService _storageService = StorageService();
  bool _isLoading = true;
  List<Manga> _bookmarkedMangas = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get bookmarks list from storage
      await _storageService.init();
      final bookmarkUrls = await _storageService.getBookmarks();
      final lastViewedChapters = await _storageService.getAllLastViewedChapters();
      
      // Convert to list of manga objects
      _bookmarkedMangas = [];
      
      for (var mangaUrl in bookmarkUrls) {
        try {
          // Get manga details
          final mangaDetail = await _mangaService.getMangaDetails(mangaUrl);
          final lastViewedChapter = lastViewedChapters[mangaUrl] ?? {};
          
          _bookmarkedMangas.add(Manga(
            title: mangaDetail.title,
            score: mangaDetail.score,
            type: mangaDetail.type,
            demography: mangaDetail.demography,
            mangaUrl: mangaUrl,
            mangaImagen: mangaDetail.mangaImagen,
          ));
        } catch (e) {
          // Skip this manga if there's an error
          debugPrint('Error loading bookmark for $mangaUrl: $e');
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading bookmarks: $e');
    }
  }

  Future<void> _removeBookmark(String mangaUrl) async {
    try {
      await _storageService.removeBookmark(mangaUrl);
      setState(() {
        _bookmarkedMangas.removeWhere((manga) => manga.mangaUrl == mangaUrl);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from bookmarks')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookmarks'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarkedMangas.isEmpty
              ? const Center(child: Text('No bookmarks yet'))
              : ListView.builder(
                  itemCount: _bookmarkedMangas.length,
                  itemBuilder: (context, index) {
                    final manga = _bookmarkedMangas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            manga.mangaImagen,
                            width: 50,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 50,
                                height: 70,
                                color: Colors.grey,
                                child: const Icon(Icons.broken_image),
                              );
                            },
                          ),
                        ),
                        title: Text(
                          manga.title,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: FutureBuilder<Map<String, dynamic>>(
                          future: _storageService.getLastViewedChapter(manga.mangaUrl),
                          builder: (context, snapshot) {
                            final lastChapter = snapshot.data ?? {};
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Score: ${manga.score}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (lastChapter.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Last read: ${lastChapter['title'] ?? 'Unknown'}',
                                      style: const TextStyle(fontSize: 11, color: Colors.blue),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.bookmark_remove),
                              onPressed: () => _removeBookmark(manga.mangaUrl),
                              tooltip: 'Remove from bookmarks',
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MangaDetailsScreen(
                                manga: manga,
                              ),
                            ),
                          ).then((_) => _loadBookmarks());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}