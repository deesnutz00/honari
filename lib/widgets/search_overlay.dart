import 'package:flutter/material.dart';
import '../services/comprehensive_search_service.dart';
import '../models/book_model.dart';
import '../models/local_book_model.dart';
import 'search_results_widget.dart';

class SearchOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const SearchOverlay({super.key, required this.onClose});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ComprehensiveSearchService _searchService =
      ComprehensiveSearchService();

  List<BookModel> _cloudBookResults = [];
  List<LocalBookModel> _localBookResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();

    // Focus on search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(FocusNode());
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    print('🔍 SearchOverlay: Starting search for "$query"');

    if (query.trim().isEmpty) {
      print('❌ SearchOverlay: Empty query, clearing results');
      setState(() {
        _cloudBookResults = [];
        _localBookResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      print('🔍 SearchOverlay: Calling comprehensive search service...');
      final results = await _searchService.searchAllBooks(query);

      print('🔍 SearchOverlay: Got results:');
      print('   - Cloud books: ${results['cloudBooks']?.length ?? 0}');
      print('   - Local books: ${results['localBooks']?.length ?? 0}');

      setState(() {
        _cloudBookResults = results['cloudBooks'] as List<BookModel>;
        _localBookResults = results['localBooks'] as List<LocalBookModel>;
        _isLoading = false;
      });

      print('✅ SearchOverlay: Search completed successfully');
    } catch (e) {
      print('❌ SearchOverlay: Error during search: $e');
      setState(() {
        _cloudBookResults = [];
        _localBookResults = [];
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == query) {
        _performSearch(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final skyBlue = const Color(0xFF87CEEB);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: SafeArea(
            child: Column(
              children: [
                // Search header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: skyBlue, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText:
                                'Search books by title, author, or genre...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: Icon(Icons.close, color: skyBlue, size: 24),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search results or suggestions
                Expanded(
                  child: _hasSearched
                      ? SearchResultsWidget(
                          cloudBookResults: _cloudBookResults,
                          localBookResults: _localBookResults,
                          onClose: widget.onClose,
                          isLoading: _isLoading,
                        )
                      : _buildSearchSuggestions(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final skyBlue = const Color(0xFF87CEEB);
    final sakuraPink = const Color(0xFFFCE4EC);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: skyBlue.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: skyBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Search Tips',
                  style: TextStyle(
                    color: skyBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Suggestions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSuggestionItem(
                  'Try searching by book title',
                  'e.g., "Harry Potter", "The Hobbit"',
                  Icons.book,
                  skyBlue,
                ),
                const SizedBox(height: 16),
                _buildSuggestionItem(
                  'Search by author name',
                  'e.g., "J.K. Rowling", "Tolkien"',
                  Icons.person,
                  sakuraPink,
                ),
                const SizedBox(height: 16),
                _buildSuggestionItem(
                  'Find books by genre',
                  'e.g., "Fantasy", "Science Fiction"',
                  Icons.category,
                  skyBlue,
                ),
                const SizedBox(height: 16),
                _buildSuggestionItem(
                  'Use partial words',
                  'e.g., "har" for "Harry Potter"',
                  Icons.search,
                  sakuraPink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
