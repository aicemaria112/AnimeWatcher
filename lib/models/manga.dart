class Manga {
  final String title;
  final String score;
  final String type;
  final String demography;
  final String mangaUrl;
  final String mangaImagen;

  Manga({
    required this.title,
    required this.score,
    required this.type,
    required this.demography,
    required this.mangaUrl,
    required this.mangaImagen,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    return Manga(
      title: json['title'] ?? '',
      score: json['score'] ?? '0.00',
      type: json['type'] ?? '',
      demography: json['publicationDemographic'] ?? '',
      mangaUrl: json['id'] ?? '',
      mangaImagen: json['coverUrl'] ?? '',
    );
  }
}

class MangaDetail extends Manga {
  final String description;
  final String status;
  final List<String> genres;
  final List<Chapter> chapters;
  final bool hasMoreChapters;
  final int totalChapters;
  final List<String> authors;

  MangaDetail({
    required super.title,
    required super.score,
    required super.type,
    required super.demography,
    required super.mangaUrl,
    required super.mangaImagen,
    required this.description,
    required this.status,
    required this.genres,
    required this.chapters,
    this.hasMoreChapters = false,
    this.totalChapters = 0,
    required this.authors,
  });

  factory MangaDetail.fromJson(Map<String, dynamic> json) {
    return MangaDetail(
      title: json['title'] ?? '',
      score: json['score'] ?? '0.00',
      type: json['tipo'] ?? '',
      demography: json['demografia'] ?? '',
      mangaUrl: '',
      mangaImagen: json['image'] ?? '',
      description: json['descripcion'] ?? '',
      status: json['estado'] ?? '',
      genres: List<String>.from(json['generos'] ?? []),
      chapters: (json['capitulo'] as List<dynamic>? ?? [])
          .map((chapter) => Chapter.fromJson(chapter))
          .toList(),
      authors:[],
    );
  }
}

class Chapter {
  final String title;
  final String urlLeer;

  Chapter({
    required this.title,
    required this.urlLeer,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      title: json['Title'] ?? '',
      urlLeer: json['UrlLeer'] ?? '',
    );
  }
}