import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manga.dart';

class MangaService {
  static const String baseUrl = 'https://api.mangadex.org';

  Future<List<Manga>> getPopularMangas({int pageNumber = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/manga?limit=10&offset=${(pageNumber - 1) * 20}&order[followedCount]=desc&includes[]=cover_art&availableTranslatedLanguage[]=es'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return _processMangaList(data);
    }
    throw Exception('Failed to load popular mangas');
  }

  Future<List<Manga>> getSeinenMangas() async {
    final response = await http.get(
      Uri.parse('$baseUrl/manga?limit=10&publicationDemographic[]=seinen&includes[]=cover_art&availableTranslatedLanguage[]=es'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return _processMangaList(data);
    }
    throw Exception('Failed to load seinen mangas');
  }

  Future<List<Manga>> getJoseiMangas() async {
    final response = await http.get(
      Uri.parse('$baseUrl/manga?limit=10&publicationDemographic[]=josei&includes[]=cover_art&availableTranslatedLanguage[]=es'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return _processMangaList(data);
    }
    throw Exception('Failed to load josei mangas');
  }

  List<Manga> _processMangaList(Map<String, dynamic> data) {
    final List<dynamic> mangaList = data['data'];
    return mangaList.map((manga) {
      // Find cover art relationship
      final coverRelationship = manga['relationships']?.firstWhere(
        (rel) => rel['type'] == 'cover_art',
        orElse: () => null,
      );
      
      final String? fileName = coverRelationship?['attributes']?['fileName'];
      final String coverUrl = fileName != null 
          ? 'https://uploads.mangadex.org/covers/${manga['id']}/$fileName.512.jpg'
          : '';
      
      return Manga(
        title: manga['attributes']['title']['es'] ?? 
               manga['attributes']['title'].values.first ?? '',
        score: manga['attributes']['rating']?.toString() ?? '0.00', // Actualizado para usar rating si está disponible
        type: manga['type'] ?? '',
        demography: manga['attributes']['publicationDemographic'] ?? '',
        mangaUrl: manga['id'] ?? '',
        mangaImagen: coverUrl,
      );
    }).toList();
  }

  Future<MangaDetail> getMangaDetails(String mangaId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/manga/$mangaId?includes[]=cover_art&includes[]=author&includes[]=artist'),
    );
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> mangaData = json.decode(response.body);
      final manga = mangaData['data'];
      
      // Get cover art
      final coverRelationship = manga['relationships']?.firstWhere(
        (rel) => rel['type'] == 'cover_art',
        orElse: () => null,
      );
      
      final String? fileName = coverRelationship?['attributes']?['fileName'];
      final String coverUrl = fileName != null 
          ? 'https://uploads.mangadex.org/covers/${manga['id']}/$fileName.512.jpg'
          : '';
      
      // Get chapters
      final chaptersResponse = await http.get(
        Uri.parse('$baseUrl/manga/$mangaId/feed?limit=100&translatedLanguage[]=es&translatedLanguage[]=es-la&order[volume]=desc&order[chapter]=desc'),
      );
      
      List<Chapter> chapters = [];
      if (chaptersResponse.statusCode == 200) {
        final Map<String, dynamic> chaptersData = json.decode(chaptersResponse.body);
        chapters = (chaptersData['data'] as List).map((chapter) {
          return Chapter(
            title: chapter['attributes']['title']!= null ? (chapter['attributes']['title']!= "" ? chapter['attributes']['title'] :  'Chapter ${chapter['attributes']['chapter'] ?? ''}') :  'Chapter ${chapter['attributes']['chapter'] ?? ''}',
            urlLeer: chapter['id'],
          );
        }).toList();
      }
      
      // Get tags/genres
      final List<String> genres = (manga['attributes']['tags'] as List?)
          ?.where((tag) => tag['type'] == 'tag')
          ?.map<String>((tag) => tag['attributes']['name']['en'] ?? '')
          ?.toList() ?? [];
      
      return MangaDetail(
        title: manga['attributes']['title']['en'] ?? 
               manga['attributes']['title'].values.first ?? '',
        score: (await getMangaRatingAverage(mangaId)).toString(),
        type: manga['type'] ?? '',
        demography: manga['attributes']['publicationDemographic'] ?? '',
        mangaUrl: manga['id'],
        mangaImagen: coverUrl,
        description: manga['attributes']['description']['es'] ?? manga['attributes']['description']['es-la'] ??
                    manga['attributes']['description']['en'] ??
                    manga['attributes']['description'].values.first ?? '',
        status: manga['attributes']['status'] ?? '',
        genres: genres,
        chapters: chapters,
      );
    }
    throw Exception('Failed to load manga details');
  }

  Future<List<String>> getChapterImages(String chapterId) async {
    // First get the at-home server URL
    final serverResponse = await http.get(
      Uri.parse('$baseUrl/at-home/server/$chapterId'),
    );
    
    if (serverResponse.statusCode == 200) {
      final Map<String, dynamic> serverData = json.decode(serverResponse.body);
      final String baseUrl = serverData['baseUrl'];
      final String hash = serverData['chapter']['hash'];
      final List<dynamic> data = serverData['chapter']['dataSaver'];
      
      // Construct image URLs
      return data.map<String>((imageName) {
        return '$baseUrl/data-saver/$hash/$imageName';
      }).toList();
    }
    throw Exception('Failed to load chapter images');
  }

  Future<List<Manga>> searchManga(String title) async {
    final response = await http.get(
      Uri.parse('$baseUrl/manga?title=$title&includes[]=cover_art&limit=20&availableTranslatedLanguage[]=es'),
    );
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return _processMangaList(data);
    }
    throw Exception('Failed to search manga');
  }

  Future<double> getMangaRatingAverage(String mangaId) async {
        final response = await http.get(
            Uri.parse('$baseUrl/statistics/manga/$mangaId'),
        );

        if (response.statusCode == 200) {
            final Map<String, dynamic> data = json.decode(response.body);
            final double averageRating = data['statistics'][mangaId]['rating']['average'];
            return double.parse(averageRating.toStringAsFixed(2));
        }
        throw Exception('Failed to load manga rating average');
    }
}