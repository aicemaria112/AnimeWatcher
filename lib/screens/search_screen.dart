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
  final List<String> _demographics = ['Shounen', 'Seinen', 'Shoujo', 'Josei'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchManga() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a search term';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _mangaService.searchManga(_searchController.text);
      setState(() {
        _searchResults = results;
        
        // Apply filters if selected
        if (_selectedType != null) {
          _searchResults = _searchResults!.where(
            (manga) => manga.type == _selectedType
          ).toList();
        }
        
        if (_selectedDemography != null) {
          _searchResults = _searchResults!.where(
            (manga) => manga.demography == _selectedDemography
          ).toList();
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
      appBar: AppBar(
        title: const Text('Search Manga'),
      ),
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedType,
                        items: [null, ..._types].map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type ?? 'All Types'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Demography',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedDemography,
                        items: [null, ..._demographics].map((demo) {
                          return DropdownMenuItem<String>(
                            value: demo,
                            child: Text(demo ?? 'All Demographics'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDemography = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _searchManga,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _searchResults == null
                        ? const Center(child: Text('Search for manga'))
                        : _searchResults!.isEmpty
                            ? const Center(child: Text('No results found'))
                            : GridView.builder(
                                padding: const EdgeInsets.all(16.0),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.7,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _searchResults!.length,
                                itemBuilder: (context, index) {
                                  return MangaCard(
                                    manga: _searchResults![index],
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MangaDetailsScreen(
                                            manga: _searchResults![index],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }
}