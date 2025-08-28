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
      final response = await Supabase.instance.client
          .from('posts')
          .select('*, users!inner(*)')
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> formattedPosts = [];

      for (var post in response) {
        String? bookTitle;
        String? bookCover;

        if (post['book_id'] != null) {
          final bookResponse = await Supabase.instance.client
              .from('books')
              .select('*')
              .eq('id', post['book_id'])
              .maybeSingle();

          if (bookResponse != null) {
            bookTitle = '${bookResponse['title']} by ${bookResponse['author']}';
            bookCover = bookResponse['cover_url'] ?? 'assets/book.png';
          }
        }

        final likeCount = await Supabase.instance.client
            .from('post_likes')
            .count();

        final commentCount = await Supabase.instance.client
            .from('post_comments')
            .count();

        formattedPosts.add({
          'id': post['id'],
          'username': post['users']['username'],
          'avatar': post['users']['avatar_url'] ?? 'assets/user.jpg',
          'content': post['content'],
          'bookTitle': bookTitle ?? '',
          'bookCover': bookCover ?? 'assets/book.png',
          'type': post['type'] ?? 'Post',
          'likes': likeCount,
          'comments': commentCount,
          'timeAgo': _getTimeAgo(DateTime.parse(post['created_at'])),
        });
      }

      setState(() {
        _posts = formattedPosts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to format "time ago"
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    } else {
      return 'Just now';
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
          style: TextStyle(
            color: Color(0xFF87CEEB),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF7D7D7D)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF7D7D7D),
            ),
            onPressed: () {
              // TODO: Open Create Post Modal
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Tabs
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: ['All Posts', 'Following', 'Reviews'].map((label) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF87CEEB),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0E0E0).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: post['avatar'].toString().startsWith('http')
                      ? NetworkImage(post['avatar'])
                      : AssetImage(post['avatar']) as ImageProvider,
                ),
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
                    color: const Color(0xFF87CEEB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post['type'],
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Post Content
            Text(post['content'] ?? '', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            // Book reference (only show if exists)
            if (post['bookTitle'] != '')
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Image(
                      image: post['bookCover'].toString().startsWith('http')
                          ? NetworkImage(post['bookCover'])
                          : AssetImage(post['bookCover']) as ImageProvider,
                      height: 40,
                      width: 30,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        post['bookTitle'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7D7D7D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            // Interaction Bar
            Row(
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 20,
                  color: Color(0xFF7D7D7D),
                ),
                const SizedBox(width: 4),
                Text(
                  '${post['likes']}',
                  style: const TextStyle(color: Color(0xFF7D7D7D)),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: Color(0xFF7D7D7D),
                ),
                const SizedBox(width: 4),
                Text(
                  '${post['comments']}',
                  style: const TextStyle(color: Color(0xFF7D7D7D)),
                ),
                const Spacer(),
                const Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: Color(0xFF7D7D7D),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
