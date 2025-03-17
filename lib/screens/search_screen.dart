import 'package:flutter/material.dart';
import '../models/manga.dart';
import '../services/manga_service.dart';
import '../widgets/manga_card.dart';
import '../screens/manga_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final MangaService _mangaService = MangaService();
  final TextEditingController _searchController = TextEditingController();
  List<Manga>? _searchResults;
  bool _isLoading = false;
  String? _errorMessage;

  // Filter options
  String? _selectedType;
  String? _selectedDemography;

  final List<String> _types = ['MANGA', 'MANHWA', 'MANHUA', 'NOVEL'];
  final List<String> _demographics = ['shounen', 'seinen', 'shoujo', 'josei'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchManga() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Allow empty search to show all available manga
      final results =
          _searchController.text.isEmpty
              ? await _mangaService.getPopularMangas()
              : await _mangaService.searchManga(_searchController.text);

      setState(() {
        _searchResults = results;

        // Apply filters if selected
        if (_selectedType != null) {
          _searchResults =
              _searchResults!
                  .where((manga) => manga.type == _selectedType)
                  .toList();
        }

        if (_selectedDemography != null) {
          _searchResults =
              _searchResults!
                  .where((manga) => manga.demography == _selectedDemography)
                  .toList();
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching manga: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Manga')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by title...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onSubmitted: (_) => _searchManga(),
                ),
                const SizedBox(height: 16),
                // Use Column instead of Row to prevent overflow
                Column(
                  children: [
                    // DropdownButtonFormField<String>(
                    //   isExpanded: true, // Prevent overflow
                    //   decoration: const InputDecoration(
                    //     labelText: 'Type',
                    //     border: OutlineInputBorder(),
                    //     contentPadding: EdgeInsets.symmetric(
                    //       horizontal: 12,
                    //       vertical: 8,
                    //     ),
                    //   ),
                    //   value: _selectedType,
                    //   items:
                    //       [null, ..._types].map((type) {
                    //         return DropdownMenuItem<String>(
                    //           value: type,
                    //           child: Text(
                    //             type ?? 'All Types',
                    //             overflow: TextOverflow.ellipsis,
                    //           ),
                    //         );
                    //       }).toList(),
                    //   onChanged: (value) {
                    //     setState(() {
                    //       _selectedType = value;
                    //     });
                    //   },
                    // ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true, // Prevent overflow
                      decoration: const InputDecoration(
                        labelText: 'Demography',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      value: _selectedDemography,
                      items:
                          [null, ..._demographics].map((demo) {
                            return DropdownMenuItem<String>(
                              value: demo,
                              child: Text(
                                demo ?? 'All Demographics',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDemography = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _searchManga,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Search',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _searchResults == null
                    ? const Center(child: Text('Search for manga'))
                    : _searchResults!.isEmpty
                    ? const Center(child: Text('No results found'))
                    : GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.6, // Reducido de 0.7 para hacer las tarjetas más altas
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _searchResults!.length,
                      itemBuilder: (context, index) {
                        // return MangaCard(
                        //   manga: _searchResults![index],
                        //   onTap: () {
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //         builder: (context) => MangaDetailsScreen(
                        //           manga: _searchResults![index],
                        //         ),
                        //       ),
                        //     );
                        //   },
                        // );
                        return SizedBox(
                          width: 200,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: MangaCard(
                              manga: _searchResults![index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => MangaDetailsScreen(
                                          manga: _searchResults![index],
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
