import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color skyBlue = const Color(0xFF87CEEB);
  final Color lightSkyBlue = const Color(0xFFE0F0FF);

  UserModel? _user;
  Map<String, int> _stats = {};
  bool _isLoading = true;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getCurrentUser();
      if (user != null) {
        final stats = await _userService.getUserStats(user.id);
        setState(() {
          _user = user;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: skyBlue,
                          ),
                        ),
                        Icon(Icons.settings, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Profile pic
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: _user?.avatarUrl != null
                          ? NetworkImage(_user!.avatarUrl!)
                          : const AssetImage('assets/user.jpg')
                                as ImageProvider,
                    ),
                    const SizedBox(height: 12),

                    // Name
                    Text(
                      _user?.username ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Bio
                    Text(
                      _user?.bio ?? 'No bio available',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),

                    // Edit Profile Button
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF87CEEB),
                        side: const BorderSide(color: Color(0xFF87CEEB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                    const SizedBox(height: 24),

                    // Stats Section
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatBox(
                            '${_stats['books_shared'] ?? 0}',
                            'Books\nShared',
                            Icons.menu_book_outlined,
                            color: skyBlue,
                          ),
                          _buildStatBox(
                            '${_stats['favorites'] ?? 0}',
                            'Favorites',
                            Icons.favorite_border,
                            color: skyBlue,
                          ),
                          _buildStatBox(
                            '${_stats['following'] ?? 0}',
                            'Following',
                            Icons.person_outline,
                            color: skyBlue,
                          ),
                          _buildStatBox(
                            '${_stats['followers'] ?? 0}',
                            'Followers',
                            Icons.people_outline,
                            color: skyBlue,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Achievements
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Achievements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF87CEEB),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAchievementCard(
                      '🌸 First Book Shared',
                      'You\'ve uploaded your first book!',
                    ),
                    const SizedBox(height: 12),
                    _buildAchievementCard(
                      '🌸 Favorite Collector',
                      'You\'ve saved over 100 books to your favorites.',
                    ),
                    const SizedBox(height: 12),
                    _buildAchievementCard(
                      '🌸 Community Builder',
                      'You\'re now followed by 200+ readers.',
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStatBox(
    String number,
    String label,
    IconData icon, {
    Color color = Colors.blueAccent,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          number,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE0F0FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF87CEEB),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
