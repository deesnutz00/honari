import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';

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
  final BookService _bookService = BookService();
  Set<String> _likedPosts = {}; // Track liked posts by current user

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadUserLikes();
  }

  Future<void> _loadPosts() async {
    try {
      print('Loading posts...');

      // Check authentication first
      final user = Supabase.instance.client.auth.currentUser;
      print('Current user: ${user?.id ?? "Not authenticated"}');

      // First try a simple query without joins
      print('Testing basic Supabase connection...');
      try {
        final testQuery = await Supabase.instance.client
            .from('posts')
            .select('count')
            .limit(1);
        print('Basic query successful: $testQuery');
      } catch (basicError) {
        print('❌ Basic query failed: $basicError');
        print('❌ This indicates a fundamental Supabase connection issue');

        // Try even simpler query
        try {
          final simpleTest = await Supabase.instance.client
              .from('posts')
              .select('*')
              .limit(1);
          print('Simple query successful: ${simpleTest.length} records');
        } catch (simpleError) {
          print('❌ Even simple query failed: $simpleError');
          print('❌ Check Supabase URL and anon key in your app');
        }
      }

      // Fetch posts and user profiles separately to avoid relationship issues
      final postsResponse = await Supabase.instance.client
          .from('posts')
          .select('*')
          .order('created_at', ascending: false);

      print('Posts fetched: ${postsResponse.length}');

      // Get unique user IDs from posts
      final userIds = postsResponse
          .map((post) => post['user_id'])
          .toSet()
          .toList();

      // Fetch user profiles for these users
      final profilesResponse = await Supabase.instance.client
          .from('user_profiles')
          .select('*')
          .inFilter('id', userIds);

      print('Profiles fetched: ${profilesResponse.length}');

      // Create a map of user_id -> profile for easy lookup
      final profilesMap = {
        for (var profile in profilesResponse) profile['id']: profile,
      };

      // Combine posts with profiles
      final response = postsResponse.map((post) {
        final userId = post['user_id'];
        return {...post, 'user_profiles': profilesMap[userId]};
      }).toList();

      print('Posts query response: ${response.length} posts found');
      print('Raw response: $response');

      if (response.isNotEmpty) {
        print('First post sample: ${response.first}');
        print(
          'User profiles in first post: ${response.first['user_profiles']}',
        );

        // Additional debugging for user profile structure
        final post = response.first;
        if (post['user_profiles'] == null) {
          print('❌ CRITICAL: user_profiles is NULL for post ${post['id']}');
          print(
            '❌ This indicates the LEFT JOIN failed or user profile does not exist',
          );
        } else {
          print('✅ User profile found: ${post['user_profiles']['username']}');
        }
      } else {
        print(
          '❌ No posts found - checking if this is due to missing user profiles...',
        );
      }

      if (response.isEmpty) {
        print('No posts found in database - checking if posts table exists...');

        // Try a simple query to check if posts table is accessible
        try {
          final testResponse = await Supabase.instance.client
              .from('posts')
              .select('count')
              .limit(1);
          print('Posts table is accessible, count query result: $testResponse');
        } catch (testError) {
          print('Error accessing posts table: $testError');
        }

        // Try fallback query without user profiles join
        try {
          final fallbackResponse = await Supabase.instance.client
              .from('posts')
              .select('*')
              .order('created_at', ascending: false)
              .limit(1);

          print('Fallback query result: ${fallbackResponse.length} posts');
          if (fallbackResponse.isNotEmpty) {
            print('❌ Posts exist but user profiles are missing!');
            print('❌ Run the user profile creation SQL commands');
          } else {
            print('❌ No posts exist at all - create some test posts');
          }
        } catch (fallbackError) {
          print('❌ Fallback query failed: $fallbackError');
        }

        setState(() {
          _posts = [];
          _isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> formattedPosts = [];

      for (var post in response) {
        print('Processing post: ${post['id']}');

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

        // Fix: Count likes and comments for this specific post
        final likeResponse = await Supabase.instance.client
            .from('post_likes')
            .select('id')
            .eq('post_id', post['id']);

        final commentResponse = await Supabase.instance.client
            .from('post_comments')
            .select('id')
            .eq('post_id', post['id']);

        formattedPosts.add({
          'id': post['id'],
          'username': post['user_profiles'] != null
              ? (post['user_profiles']['username'] ?? 'Anonymous')
              : 'Anonymous',
          'avatar': post['user_profiles'] != null
              ? (post['user_profiles']['avatar_url'] ?? 'assets/user.jpg')
              : 'assets/user.jpg',
          'content': post['content'],
          'bookTitle': bookTitle ?? '',
          'bookCover': bookCover ?? 'assets/book.png',
          'type': post['post_type'] ?? 'review',
          'likes': likeResponse.length,
          'comments': commentResponse.length,
          'timeAgo': _getTimeAgo(DateTime.parse(post['created_at'])),
        });
      }

      print('Formatted ${formattedPosts.length} posts');

      setState(() {
        _posts = formattedPosts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading posts: $e');
      print('Error details: ${e.toString()}');

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load posts: ${e.toString()}')),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserLikes() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final likesResponse = await Supabase.instance.client
          .from('post_likes')
          .select('post_id')
          .eq('user_id', user.id);

      setState(() {
        _likedPosts = Set.from(
          likesResponse.map((like) => like['post_id'].toString()),
        );
      });
    } catch (e) {
      print('Error loading user likes: $e');
    }
  }

  Future<void> _toggleLike(String postId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to like posts')),
        );
        return;
      }

      final isLiked = _likedPosts.contains(postId);

      if (isLiked) {
        // Unlike the post
        await Supabase.instance.client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);

        setState(() {
          _likedPosts.remove(postId);
          // Update the like count in the posts list
          final postIndex = _posts.indexWhere(
            (post) => post['id'].toString() == postId,
          );
          if (postIndex != -1) {
            _posts[postIndex]['likes'] = (_posts[postIndex]['likes'] ?? 0) - 1;
          }
        });
      } else {
        // Like the post
        await Supabase.instance.client.from('post_likes').insert({
          'post_id': postId,
          'user_id': user.id,
        });

        setState(() {
          _likedPosts.add(postId);
          // Update the like count in the posts list
          final postIndex = _posts.indexWhere(
            (post) => post['id'].toString() == postId,
          );
          if (postIndex != -1) {
            _posts[postIndex]['likes'] = (_posts[postIndex]['likes'] ?? 0) + 1;
          }
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update like')));
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
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF7D7D7D),
            ),
            onPressed: () {
              _showCreatePostDialog(context);
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFCE4EC),
                      ),
                    )
                  : _posts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.post_add, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No posts yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Be the first to share your thoughts!',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) =>
                            _buildPostCard(_posts[index]),
                      ),
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                GestureDetector(
                  onTap: () => _toggleLike(post['id'].toString()),
                  child: Icon(
                    _likedPosts.contains(post['id'].toString())
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 20,
                    color: _likedPosts.contains(post['id'].toString())
                        ? const Color(0xFFFCE4EC) // Sakura pink
                        : const Color(0xFF7D7D7D),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${post['likes'] ?? 0}',
                  style: const TextStyle(color: Color(0xFF7D7D7D)),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Comments feature coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 20,
                    color: Color(0xFF7D7D7D),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${post['comments'] ?? 0}',
                  style: const TextStyle(color: Color(0xFF7D7D7D)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share feature coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.share_outlined,
                    size: 20,
                    color: Color(0xFF7D7D7D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreatePostDialog(
          bookService: _bookService,
          onPostCreated: () {
            _loadPosts(); // Refresh posts after creation
          },
        );
      },
    );
  }
}

class CreatePostDialog extends StatefulWidget {
  final BookService bookService;
  final VoidCallback onPostCreated;

  const CreatePostDialog({
    super.key,
    required this.bookService,
    required this.onPostCreated,
  });

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _bookSearchController = TextEditingController();
  String _selectedType = 'review';
  BookModel? _selectedBook;
  List<BookModel> _searchResults = [];
  bool _isSearching = false;

  final List<String> _postTypes = [
    'review',
    'currently_reading',
    'finished_reading',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    _bookSearchController.dispose();
    super.dispose();
  }

  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await widget.bookService.searchBooks(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching books: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some content')),
      );
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to create a post')),
        );
        return;
      }

      final postData = {
        'user_id': user.id,
        'content': _contentController.text.trim(),
        'post_type': _selectedType,
        if (_selectedBook != null) 'book_id': _selectedBook!.id,
      };

      print('Creating post with data: $postData');
      await Supabase.instance.client.from('posts').insert(postData);

      widget.onPostCreated();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
    } catch (e) {
      print('Error creating post: $e');
      String errorMessage = 'Failed to create post. Please try again.';

      // Handle specific foreign key errors
      if (e.toString().contains('foreign key')) {
        errorMessage =
            'Unable to create post. Please check your account and try again.';
      } else if (e.toString().contains('violates')) {
        errorMessage =
            'Post creation failed due to data validation. Please try again.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Post'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Type Dropdown
            const Text(
              'Post Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: _postTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content TextField
            const Text(
              'Content',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts, review, or recommendation...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Book Search (only show for Review and Recommendation)
            if (_selectedType == 'Review' || _selectedType == 'Recommendation')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Book (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bookSearchController,
                    decoration: const InputDecoration(
                      hintText: 'Search for a book...',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: _searchBooks,
                  ),
                  const SizedBox(height: 8),
                  if (_isSearching)
                    const Center(child: CircularProgressIndicator())
                  else if (_searchResults.isNotEmpty)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final book = _searchResults[index];
                          return ListTile(
                            leading: book.coverUrl != null
                                ? Image.network(
                                    book.coverUrl!,
                                    width: 40,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.book),
                                  )
                                : const Icon(Icons.book),
                            title: Text(book.title),
                            subtitle: Text('by ${book.author}'),
                            onTap: () {
                              setState(() {
                                _selectedBook = book;
                                _bookSearchController.text =
                                    '${book.title} by ${book.author}';
                                _searchResults = [];
                              });
                            },
                          );
                        },
                      ),
                    )
                  else if (_bookSearchController.text.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No books found'),
                    ),
                  if (_selectedBook != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Chip(
                        label: Text(
                          '${_selectedBook!.title} by ${_selectedBook!.author}',
                        ),
                        onDeleted: () {
                          setState(() {
                            _selectedBook = null;
                            _bookSearchController.clear();
                          });
                        },
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submitPost, child: const Text('Post')),
      ],
    );
  }
}
