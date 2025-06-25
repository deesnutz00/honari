import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  LibraryScreen({super.key});

  final Color skyBlue = const Color(0xFF87CEEB);
  final Color sakuraPink = const Color(0xFFFCE4EC);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "My Library",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Organize your reading journey",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.grey),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.grey),
              onPressed: () {},
            ),
          ],
          bottom: TabBar(
            labelColor: skyBlue,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            indicatorColor: skyBlue,
            tabs: const [
              Tab(text: "Playlists"),
              Tab(text: "Favorites"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Playlists Tab
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: skyBlue,
                      side: BorderSide(color: skyBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text("Create New Playlist"),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Summer Reads",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Text("12 books", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildBookCard(
                          "The Great Gatsby",
                          "F. Scott Fitzgerald",
                          "assets/book1.jpg",
                        ),
                        _buildBookCard(
                          "To Kill a Mockingbird",
                          "Harper Lee",
                          "assets/book2.jpg",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Favorites Tab
            Center(
              child: Text(
                "Your favorite books will appear here.",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(String title, String author, String imagePath) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: sakuraPink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            author,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Text(
            "Classic",
            style: TextStyle(color: Colors.blue, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
