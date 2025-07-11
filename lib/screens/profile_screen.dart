import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final Color skyBlue = const Color(0xFF87CEEB);
  final Color sakuraPink = const Color(0xFFFCE4EC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF87CEEB),
                    ),
                  ),
                  Icon(Icons.settings, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 24),

              // Profile pic
              CircleAvatar(
                radius: 48,
                backgroundImage: AssetImage(
                  'assets/user.jpg',
                ), // replace with your asset
              ),
              const SizedBox(height: 12),

              // Name
              const Text(
                'deesnutz',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 8),

              // Bio
              const Text(
                'Book lover, philosophy enthusiast, and coffee addict. Always looking for the next great read. ✨',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
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
                      '24',
                      'Books\nShared',
                      Icons.menu_book_outlined,
                      color: Color.fromARGB(255, 241, 151, 181),
                    ),
                    _buildStatBox(
                      '156',
                      'Favorites',
                      Icons.favorite_border,
                      color: Color.fromARGB(255, 241, 151, 181),
                    ),
                    _buildStatBox(
                      '89',
                      'Following',
                      Icons.person_outline,
                      color: Color.fromARGB(255, 241, 151, 181),
                    ),
                    _buildStatBox(
                      '234',
                      'Followers',
                      Icons.people_outline,
                      color: Color.fromARGB(255, 241, 151, 181),
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
                'You’ve uploaded your first book!',
              ),
              const SizedBox(height: 12),
              _buildAchievementCard(
                '🌸 Favorite Collector',
                'You’ve saved over 100 books to your favorites.',
              ),
              const SizedBox(height: 12),
              _buildAchievementCard(
                '🌸 Community Builder',
                'You’re now followed by 200+ readers.',
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
