import 'package:flutter/material.dart';
import '../models/manga.dart';
import '../services/manga_service.dart';
import '../widgets/manga_card.dart';
import '../screens/manga_details_screen.dart';
import '../screens/search_screen.dart';
import '../screens/bookmarks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MangaService _mangaService = MangaService();
  late Future<List<Manga>> _popularManga;
  late Future<List<Manga>> _joseiManga;
  late Future<List<Manga>> _seinenManga;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _popularManga = _mangaService.getPopularMangas();
    _joseiManga = _mangaService.getJoseiMangas();
  _seinenManga = _mangaService.getSeinenMangas();

  }

  Widget _buildMangaSection(String title, Future<List<Manga>> mangaFuture) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        SizedBox(
          height: 320,
          child: FutureBuilder<List<Manga>>(
            future: mangaFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No manga available'));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final manga = snapshot.data![index];
                  return SizedBox(
                    width: 200,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: MangaCard(
                        manga: manga,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MangaDetailsScreen(manga: manga),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manga Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookmarksScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _loadData()),
        child: ListView(
          children: [
            _buildMangaSection('Popular Manga', _popularManga),
            _buildMangaSection('Josei Manga', _joseiManga),
            _buildMangaSection('Seinen Manga', _seinenManga),
          ],
        ),
      ),
    );
  }
}