import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final skyBlue = const Color(0xFF87CEEB);
  final lightSkyBlue = const Color(0xFFE0F0FF);
  
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      // Mock posts for now - in a real app, you'd fetch from a posts table
      setState(() {
        _posts = [
          {
            'id': '1',
            'username': 'deesnutz',
            'avatar': 'assets/user.jpg',
            'content': 'Just finished reading "The Art of Living"...',
            'bookTitle': 'The Art of Living by Haruki Murakami',
            'bookCover': 'assets/book.png',
            'type': 'Review',
            'likes': 24,
            'comments': 8,
            'timeAgo': '2 hours ago',
          },
          {
            'id': '2',
            'username': 'bookworm',
            'avatar': 'assets/user.jpg',
            'content': 'Currently reading "1984" and it\'s absolutely mind-blowing!',
            'bookTitle': '1984 by George Orwell',
            'bookCover': 'assets/book2.png',
            'type': 'Currently Reading',
            'likes': 18,
            'comments': 5,
            'timeAgo': '4 hours ago',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) =>
                        _buildPostCard(_posts[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
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
                CircleAvatar(backgroundImage: AssetImage(post['avatar'])),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['username'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      post['timeAgo'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                    color: lightSkyBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(post['type'], style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Post Content
            Text(
              post['content'],
              style: const TextStyle(fontSize: 14),
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
                    post['bookCover'],
                    height: 40,
                    width: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      post['bookTitle'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Interaction Bar
            Row(
              children: [
                const Icon(Icons.favorite_border, size: 20, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${post['likes']}'),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${post['comments']}'),
                const Spacer(),
                const Icon(Icons.share_outlined, size: 20, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
