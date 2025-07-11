import 'package:flutter/material.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final skyBlue = const Color(0xFF87CEEB);
    final sakuraPink = const Color(0xFFFCE4EC);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Social Feed',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
            onPressed: () {
              // TODO: Open Create Post Modal
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: ['All Posts', 'Following', 'Reviews'].map((label) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Chip(
                    label: Text(label),
                    backgroundColor: skyBlue.withOpacity(0.1),
                  ),
                );
              }).toList(),
            ),
          ),

          // Post Feed
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: 5, // Mock posts
              itemBuilder: (context, index) =>
                  _buildPostCard(skyBlue, sakuraPink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Color skyBlue, Color sakuraPink) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Row(
              children: [
                CircleAvatar(backgroundImage: AssetImage('assets/user.jpg')),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "deesnutz",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "2 hours ago",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: sakuraPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text("Review", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Post Content
            const Text(
              'Just finished reading "The Art of Living"...',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            // Book reference
            Container(
              decoration: BoxDecoration(
                color: skyBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Image.asset(
                    'assets/book.png',
                    height: 40,
                    width: 30,
                  ), // Placeholder
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "The Art of Living by Haruki Murakami",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Interaction Bar
            Row(
              children: const [
                Icon(Icons.favorite_border, size: 20, color: Colors.grey),
                SizedBox(width: 4),
                Text('24'),
                SizedBox(width: 12),
                Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                SizedBox(width: 4),
                Text('8'),
                Spacer(),
                Icon(Icons.share_outlined, size: 20, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
