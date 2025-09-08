import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/book_service.dart';
import 'login_screen.dart';

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
  bool _hasError = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _achievements = [];
  final UserService _userService = UserService();
  final BookService _bookService = BookService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final user = await _userService.getCurrentUser();
      if (user != null) {
        // Load stats and achievements in parallel for better performance
        final results = await Future.wait([
          _userService.getUserStats(user.id),
          _loadUserAchievements(user.id),
        ]);

        if (!mounted) return;

        setState(() {
          _user = user;
          _stats = results[0] as Map<String, int>;
          _achievements = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage =
              'Profile not found. This might happen if your account wasn\'t set up properly during signup. Please try logging out and back in, or contact support if the issue persists.';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage =
            'Failed to load profile data. Please check your connection and try again.';
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadUserAchievements(
    String userId,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      // Get user's earned achievements with timeout
      final userAchievementsResponse = await supabase
          .from('user_achievements')
          .select(
            'achievement_id, earned_at, achievements(name, description, icon_url, points)',
          )
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 10));

      final achievements = <Map<String, dynamic>>[];
      for (final ua in userAchievementsResponse) {
        final achievement = ua['achievements'];
        if (achievement != null) {
          achievements.add({
            'id': ua['achievement_id'],
            'name': achievement['name'] ?? 'Achievement',
            'description': achievement['description'] ?? '',
            'icon_url': achievement['icon_url'],
            'points': achievement['points'] ?? 0,
            'earned_at': ua['earned_at'],
          });
        }
      }

      return achievements;
    } catch (e) {
      print('Error loading user achievements: $e');
      return [];
    }
  }

  void _showEditProfileDialog() {
    if (_user == null) return;

    final usernameController = TextEditingController(text: _user!.username);
    final bioController = TextEditingController(text: _user!.bio ?? '');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Edit Profile',
            style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.person, color: skyBlue),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.description, color: skyBlue),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final newUsername = usernameController.text.trim();
                      final newBio = bioController.text.trim();

                      if (newUsername.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Username cannot be empty'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final success = await _userService.updateUserProfile(
                          username: newUsername,
                          bio: newBio.isEmpty ? null : newBio,
                        );

                        if (success) {
                          // Reload user data
                          await _loadUserData();
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Profile updated successfully',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Failed to update profile'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        print('Error updating profile: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating profile: $e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: skyBlue,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Settings',
          style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.notifications, color: skyBlue),
                title: const Text('Notifications'),
                subtitle: const Text('Manage notification preferences'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement notification settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notification settings coming soon!'),
                      backgroundColor: skyBlue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip, color: skyBlue),
                title: const Text('Privacy'),
                subtitle: const Text('Control your privacy settings'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement privacy settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Privacy settings coming soon!'),
                      backgroundColor: skyBlue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.help, color: skyBlue),
                title: const Text('Help & Support'),
                subtitle: const Text('Get help and contact support'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement help screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Help & Support coming soon!'),
                      backgroundColor: skyBlue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.info, color: skyBlue),
                title: const Text('About'),
                subtitle: const Text('App version and information'),
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out'),
                subtitle: const Text('Sign out of your account'),
                onTap: () {
                  Navigator.pop(context);
                  _showSignOutConfirmation();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'About Honari',
          style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: skyBlue.withOpacity(0.1),
              child: Icon(Icons.book, size: 30, color: skyBlue),
            ),
            const SizedBox(height: 16),
            const Text(
              'Honari 本',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'A beautiful book reading and sharing platform',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Sign Out',
          style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to sign out? You will need to log in again to access your account.',
          style: TextStyle(color: Color(0xFF7D7D7D)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: skyBlue)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog
              await _signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      // Navigate to login screen and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Successfully signed out'),
          backgroundColor: skyBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      print('Error signing out: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: skyBlue.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: skyBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: skyBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          color: skyBlue,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFCE4EC)),
                  )
                : _hasError
                ? _buildErrorView()
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
                          IconButton(
                            icon: Icon(Icons.settings, color: Colors.grey),
                            onPressed: _showSettingsDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Profile pic
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFCE4EC),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundImage: _user?.avatarUrl != null
                              ? NetworkImage(_user!.avatarUrl!)
                              : const AssetImage('assets/user.jpg')
                                    as ImageProvider,
                        ),
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
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Edit Profile Button
                      OutlinedButton(
                        onPressed: _showEditProfileDialog,
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
                      if (_achievements.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Color(0xFFF7FAFD),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Color(0xFFE0F0FF)),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.emoji_events_outlined,
                                size: 48,
                                color: skyBlue.withOpacity(0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No achievements yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Keep reading and sharing to unlock achievements!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._achievements.map(
                          (achievement) => Column(
                            children: [
                              _buildAchievementCard(
                                achievement['name'] ?? 'Achievement',
                                achievement['description'] ?? '',
                                points: achievement['points'] ?? 0,
                                earnedAt: achievement['earned_at'],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                    ],
                  ),
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

  Widget _buildAchievementCard(
    String title,
    String description, {
    int points = 0,
    String? earnedAt,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF87CEEB),
                  ),
                ),
              ),
              if (points > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: skyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+$points pts',
                    style: TextStyle(
                      color: skyBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          if (earnedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Earned ${_formatEarnedDate(earnedAt)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  String _formatEarnedDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'today';
      } else if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks week${weeks > 1 ? 's' : ''} ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
