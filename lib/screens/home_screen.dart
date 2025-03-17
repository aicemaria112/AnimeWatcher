import 'dart:async';

import 'package:flutter/material.dart';
import '../models/manga.dart';
import '../services/manga_service.dart';
import '../widgets/manga_card.dart';
import '../screens/manga_details_screen.dart';
import '../screens/search_screen.dart';
import '../screens/bookmarks_screen.dart';
import 'package:flutter/services.dart';


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
  double _opacity = 1.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAnimation();
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

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      setState(() {
        _opacity = _opacity == 1.0 ? 0.3 : 1.0;
      });
    });
  }

  void _showDonationDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: AlertDialog(
                backgroundColor: Theme.of(context).dialogBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Text(
                        '✨ ¡Colabora con MangaVibe!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(
                        Icons.info,
                        'Versión',
                        'MangaVibe v1.0.0',
                      ),
                      _buildInfoRow(
                        Icons.favorite,
                        'Tu apoyo es clave',
                        'Tu contribución nos ayuda a mejorar la aplicación y mantener los servidores. ¡Cada donación cuenta!',
                      ),
                      _buildAccountInfo(),
                      _buildEmailRow(),
                      const SizedBox(height: 20),
                      Text(
                        '¡Gracias por tu confianza! 😊',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cerrar',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
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

  Widget _buildInfoRow(IconData icon, String title, String text) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAccountInfo() {
    return ListTile(
      leading: Icon(Icons.payment, color: Theme.of(context).colorScheme.primary),
      title: Text('Donar a', style: Theme.of(context).textTheme.titleSmall),
      subtitle: Row(
        children: [
          Text(
            '9204 1299 7519 0036',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.content_copy, size: 18),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: '9204 1299 7519 0036'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Número copiado! 🎉')),
              );
            },
          ),
        ],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildEmailRow() {
    return ListTile(
      leading: Icon(Icons.bug_report, color: Theme.of(context).colorScheme.primary),
      title: Text('Reportar errores', style: Theme.of(context).textTheme.titleSmall),
      subtitle: GestureDetector(
        onTap: () async {
          final url = Uri.parse('mailto:aicemaria112@gmail.com');
        },
        child: Text(
          'mailto:aicemaria112@gmail.com',
          style: TextStyle(
            color: Colors.blue.shade700,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
          IconButton(
      icon: const Icon(Icons.favorite, color: Colors.white),
      color: Colors.pinkAccent,
      onPressed: () => _showDonationDialog(context),
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
