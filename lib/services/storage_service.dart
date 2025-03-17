import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/manga.dart';

class StorageService {
  static const String readingProgressKey = 'reading_progress';
  static const String bookmarksKey = 'bookmarks';
  static const String lastViewedChapterKey = 'last_viewed_chapter';
  
  // Singleton instance
  static final StorageService _instance = StorageService._internal();
  
  // Factory constructor to return the same instance
  factory StorageService() {
    return _instance;
  }
  
  // Private constructor for singleton
  StorageService._internal();
  
  // SharedPreferences instance
  SharedPreferences? _prefs;
  // Initialization flag
  bool _initialized = false;
  // Future to track initialization
  Future<void>? _initializationFuture;
  
  Future<void> init() async {
    if (!_initialized && _initializationFuture == null) {
      _initializationFuture = _initializePrefs();
    }
    return _initializationFuture;
  }
  
  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }
  
  // Helper method to ensure initialization
  Future<SharedPreferences> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
    return _prefs!;
  }

  Future<void> saveReadingProgress(String mangaUrl, String chapterUrl, int page) async {
    final prefs = await _ensureInitialized();
    final progress = prefs.getString(readingProgressKey) ?? '{}';
    final Map<String, dynamic> progressMap = json.decode(progress);
    
    if (!progressMap.containsKey(mangaUrl)) {
      progressMap[mangaUrl] = {};
    }
    progressMap[mangaUrl][chapterUrl] = page;
    
    await prefs.setString(readingProgressKey, json.encode(progressMap));
  }

  Future<int> getReadingProgress(String mangaUrl, String chapterUrl) async {
    final prefs = await _ensureInitialized();
    final progress = prefs.getString(readingProgressKey) ?? '{}';
    final Map<String, dynamic> progressMap = json.decode(progress);
    
    return progressMap[mangaUrl]?[chapterUrl] ?? 0;
  }

  Future<String> getDownloadDirectory() async {
    Directory appDir;
    if (Platform.isAndroid) {
      appDir = Directory('/storage/emulated/0/Download');
    } else {
      final downloadsDir = await getDownloadsDirectory();
      appDir = downloadsDir ?? await getApplicationDocumentsDirectory();
    }
    final downloadDir = Directory('${appDir.path}/manga_downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  Future<String> getMangaDownloadPath(String mangaTitle) async {
    final downloadDir = await getDownloadDirectory();
    final mangaDir = Directory('$downloadDir/${_sanitizeFileName(mangaTitle)}');
    if (!await mangaDir.exists()) {
      await mangaDir.create(recursive: true);
    }
    return mangaDir.path;
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  // Bookmark methods
  Future<void> addBookmark(String mangaUrl) async {
    final prefs = await _ensureInitialized();
    final bookmarks = prefs.getStringList(bookmarksKey) ?? [];
    if (!bookmarks.contains(mangaUrl)) {
      bookmarks.add(mangaUrl);
      await prefs.setStringList(bookmarksKey, bookmarks);
    }
  }

  Future<void> removeBookmark(String mangaUrl) async {
    final prefs = await _ensureInitialized();
    final bookmarks = prefs.getStringList(bookmarksKey) ?? [];
    if (bookmarks.contains(mangaUrl)) {
      bookmarks.remove(mangaUrl);
      await prefs.setStringList(bookmarksKey, bookmarks);
    }
  }

  Future<bool> isBookmarked(String mangaUrl) async {
    final prefs = await _ensureInitialized();
    final bookmarks = prefs.getStringList(bookmarksKey) ?? [];
    return bookmarks.contains(mangaUrl);
  }

  Future<List<String>> getBookmarks() async {
    final prefs = await _ensureInitialized();
    return prefs.getStringList(bookmarksKey) ?? [];
  }

  // Check if a chapter is downloaded
  Future<bool> isChapterDownloaded(String mangaTitle, String chapterTitle) async {
    final mangaDir = await getMangaDownloadPath(_sanitizeFileName(mangaTitle));
    final pdfFile = File('$mangaDir/$chapterTitle.pdf');
    return await pdfFile.exists();
  }

  // Last viewed chapter methods
  Future<void> saveLastViewedChapter(String mangaUrl, String chapterTitle, String chapterUrl) async {
    final prefs = await _ensureInitialized();
    final lastViewedMap = prefs.getString(lastViewedChapterKey) ?? '{}';
    final Map<String, dynamic> lastViewedData = json.decode(lastViewedMap);
    
    lastViewedData[mangaUrl] = {
      'title': chapterTitle,
      'url': chapterUrl
    };
    
    await prefs.setString(lastViewedChapterKey, json.encode(lastViewedData));
  }

  Future<Map<String, dynamic>> getLastViewedChapter(String mangaUrl) async {
    final prefs = await _ensureInitialized();
    final lastViewedMap = prefs.getString(lastViewedChapterKey) ?? '{}';
    final Map<String, dynamic> lastViewedData = json.decode(lastViewedMap);
    
    return lastViewedData[mangaUrl] ?? {};
  }

  Future<Map<String, dynamic>> getAllLastViewedChapters() async {
    final prefs = await _ensureInitialized();
    final lastViewedMap = prefs.getString(lastViewedChapterKey) ?? '{}';
    return json.decode(lastViewedMap);
  }
}