import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';
import 'upload_screen.dart';
import 'library_screen.dart';
import 'social_screen.dart';
import 'book_details.dart';
import 'book_reader_screen.dart';
import 'package:honari/widgets/search_overlay.dart';
import '../models/book_model.dart';
import '../models/local_book_model.dart';
import '../services/book_service.dart';
import '../services/local_book_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isSearchVisible = false;
  bool _isLoading = true;

  final Color skyBlue = const Color(0xFF87CEEB);
  final Color sakuraPink = const Color(0xFFFCE4EC);

  // Database services
  final BookService _bookService = BookService();
  final LocalBookService _localBookService = LocalBookService();

  // Book data
  List<BookModel> _trendingBooks = [];
  List<BookModel> _recommendedBooks = [];
  List<BookModel> _recentBooks = [];
  List<LocalBookModel> _localBooks = [];
  final String _dailyQuote =
      "Replace this with dynamic quotes from your database when ready.";
  final String _quoteAuthor = "— Honari";

  // Remove the _screens list initialization from initState
  // We'll build screens on-demand to prevent memory issues

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load trending books (most recent books)
      final allBooks = await _bookService.getAllBooks();
      _trendingBooks = allBooks.take(8).toList();

      // Load user's recent books (books they've interacted with recently)
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userBooks = await _bookService.getUserBooks(user.id);
        _recentBooks = userBooks.take(8).toList();

        // Use the same books as trending but in reverse order for recommendations
        _recommendedBooks = _trendingBooks.reversed.toList();
      } else {
        // If no user, show trending books in reverse order as recommendations
        _recommendedBooks = _trendingBooks.reversed.toList();
        _recentBooks = [];
      }

      // Load local books from device storage
      _localBooks = await _localBookService.getLocalBooks();

      // Load daily quote (for now, keep static, but could be from database)
      // TODO: Implement dynamic quotes from database
    } catch (e) {
      print('Error loading dashboard data: $e');
      // Keep empty lists on error
      _trendingBooks = [];
      _recommendedBooks = [];
      _recentBooks = [];
      _localBooks = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showSearch() {
    setState(() {
      _isSearchVisible = true;
    });
  }

  void _hideSearch() {
    setState(() {
      _isSearchVisible = false;
    });
  }

  // Helper method to get the current screen
  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return LibraryScreen();
      case 2:
        return const SocialScreen();
      case 3:
        return const UploadScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFCE4EC)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        bottom: 24,
      ), // Remove horizontal padding since ListView has its own
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16), // Add top padding
          _buildSection("Trending Now"),
          _buildBookList(_trendingBooks, "trending"),

          const SizedBox(height: 20), // Reduced spacing for compact design
          _buildSection("Recommendations from Friends"),
          _buildBookList(_recommendedBooks, "recommendations"),

          const SizedBox(height: 20), // Reduced spacing for compact design
          _buildSection("Recently Opened"),
          _buildBookList(_recentBooks, "recent"),

          const SizedBox(height: 20), // Reduced spacing for compact design
          _buildSection("Local Library"),
          _buildLocalBookList(_localBooks),

          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDailyQuote(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF87CEEB), // sky blue
        ),
      ),
    );
  }

  Widget _buildBookList(List<BookModel> books, String type) {
    if (books.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Text(
          "No ${type == "trending"
              ? "trending"
              : type == "recommendations"
              ? "recommended"
              : "recent"} books available",
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      );
    }

    return SizedBox(
      height: 210, // Reduced height for smaller cards
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ), // Add horizontal padding
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return _buildBookCard(book, type);
        },
      ),
    );
  }

  Widget _buildLocalBookList(List<LocalBookModel> books) {
    if (books.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Text(
          "No local books available",
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      );
    }

    return SizedBox(
      height: 210, // Reduced height for smaller cards
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ), // Add horizontal padding
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return _buildLocalBookCard(book);
        },
      ),
    );
  }

  Widget _buildBookCard(BookModel book, String type) {
    return GestureDetector(
      onTap: () {
        try {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book)),
          );
        } catch (e) {
          // Show error dialog if navigation fails
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                'Error',
                style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold),
              ),
              content: Text('Failed to open book details: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK', style: TextStyle(color: skyBlue)),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        width: 120, // Reduced width to prevent overflow
        margin: const EdgeInsets.only(right: 8), // Reduced margin
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Book Cover Container with fixed dimensions
            Container(
              height: 160, // Reduced height
              width: 120, // Reduced width
              decoration: BoxDecoration(
                color: skyBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: skyBlue.withOpacity(0.3), width: 1),
              ),
              child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderCover(type);
                        },
                      ),
                    )
                  : _buildPlaceholderCover(type),
            ),

            // Only show book title
            const SizedBox(height: 6),
            SizedBox(
              height: 36, // Fixed height for title
              child: Text(
                book.title,
                style: const TextStyle(
                  fontSize: 12, // Smaller font
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalBookCard(LocalBookModel book) {
    return GestureDetector(
      onTap: () {
        // Navigate directly to book reader for local books
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookReaderScreen(
              book: book,
              localBookService: _localBookService,
            ),
          ),
        );
      },
      child: Container(
        width: 120, // Reduced width to prevent overflow
        margin: const EdgeInsets.only(right: 8), // Reduced margin
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Book Cover Container with fixed dimensions
            Container(
              height: 160, // Reduced height
              width: 120, // Reduced width
              decoration: BoxDecoration(
                color: skyBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: skyBlue.withOpacity(0.3), width: 1),
              ),
              child: book.coverPath != null && book.coverPath!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(book.coverPath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildLocalPlaceholderCover();
                        },
                      ),
                    )
                  : _buildLocalPlaceholderCover(),
            ),

            // Only show book title
            const SizedBox(height: 6),
            SizedBox(
              height: 36, // Fixed height for title
              child: Text(
                book.title,
                style: const TextStyle(
                  fontSize: 12, // Smaller font
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover(String type) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.book, size: 32, color: skyBlue.withOpacity(0.6)),
        const SizedBox(height: 4),
        Text(
          type == "trending"
              ? "Trending\nBook"
              : type == "recommendations"
              ? "Recommended\nBook"
              : "Recent\nBook",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: skyBlue.withOpacity(0.7),
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLocalPlaceholderCover() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.sd_storage, size: 32, color: skyBlue.withOpacity(0.6)),
        const SizedBox(height: 4),
        Text(
          "Local\nBook",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: skyBlue.withOpacity(0.7),
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyQuote() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sakuraPink.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sakuraPink.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.format_quote,
                color: sakuraPink.withOpacity(0.7),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                "Daily Quote",
                style: TextStyle(
                  color: sakuraPink.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _dailyQuote,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "— Honari",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: sakuraPink.withOpacity(0.7),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // TODO: Replace this method when you add database functionality
  // Widget _buildHorizontalList() {
  //   return SizedBox(
  //     height: 220,
  //     child: ListView(
  //       scrollDirection: Axis.horizontal,
  //       children: [
  //         // Replace with dynamic data from your database
  //         // Example: books.map((book) => BookCard(book: book)).toList()
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Honari 本',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF87CEEB),
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _showSearch,
                  icon: const Icon(Icons.search, color: Colors.grey),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Implement notifications functionality
                  },
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Builder(
            builder: (context) {
              try {
                return _getCurrentScreen();
              } catch (e) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text('Error loading screen: $e'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            // Force rebuild
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),

          // Search overlay
          if (_isSearchVisible) SearchOverlay(onClose: _hideSearch),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: skyBlue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline), // Message circle icon
            label: 'Social',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_outlined),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
