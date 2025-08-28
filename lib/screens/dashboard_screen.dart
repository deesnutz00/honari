import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'upload_screen.dart';
import 'library_screen.dart';
import 'social_screen.dart';
import 'book_details.dart';
import 'package:honari/widgets/book_card.dart';
import 'package:honari/widgets/search_overlay.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isSearchVisible = false;

  final Color skyBlue = const Color(0xFF87CEEB);
  final Color sakuraPink = const Color(0xFFFCE4EC);

  // Remove the _screens list initialization from initState
  // We'll build screens on-demand to prevent memory issues

  @override
  void initState() {
    super.initState();
    // Removed _screens initialization to prevent memory issues
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection("Trending Now"),
          _buildPlaceholderList("trending"),

          const SizedBox(height: 16),
          _buildSection("Recommendations from Friends"),
          _buildPlaceholderList("recommendations"),

          const SizedBox(height: 16),
          _buildSection("Recently Opened"),
          _buildPlaceholderList("recent"),

          const SizedBox(height: 32),
          _buildDailyQuote(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF87CEEB), // sky blue
        ),
      ),
    );
  }

  Widget _buildPlaceholderList(String type) {
    return SizedBox(
      height: 220,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(
          3,
          (index) => _buildPlaceholderBookCard(type, index),
        ),
      ),
    );
  }

  Widget _buildPlaceholderBookCard(String type, int index) {
    return GestureDetector(
      onTap: () {
        try {
          // TODO: Replace with actual book data from database when ready
          // For now, navigate to book details with placeholder data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookDetailPage(
                title: type == "trending"
                    ? "Trending Book"
                    : type == "recommendations"
                    ? "Friend's Pick"
                    : "Recent Book",
                author: "Author Name",
                genre: "Genre",
                pages: 300,
                year: 2024,
                rating: 4.5,
                reviews: 100,
                coverUrl:
                    "", // Empty string will show placeholder in BookDetailPage
              ),
            ),
          );
        } catch (e) {
          // Show error dialog if navigation fails
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to open book details: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 180,
              width: 140,
              decoration: BoxDecoration(
                color: skyBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: skyBlue.withOpacity(0.3), width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 40, color: skyBlue.withOpacity(0.6)),
                  const SizedBox(height: 8),
                  Text(
                    type == "trending"
                        ? "Trending\nBook"
                        : type == "recommendations"
                        ? "Friend's\nPick"
                        : "Recent\nBook",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: skyBlue.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 16,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 12,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
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
            "Replace this with dynamic quotes from your database when ready.",
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
