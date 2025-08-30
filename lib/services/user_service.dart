import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      try {
        final response = await _supabase
            .from('user_profiles')
            .select()
            .eq('id', user.id)
            .single()
            .timeout(const Duration(seconds: 10));

        // Add email from auth user since it's not in user_profiles table
        final profileData = Map<String, dynamic>.from(response);
        profileData['email'] = user.email;

        return UserModel.fromJson(profileData);
      } catch (e) {
        // If profile doesn't exist, try to create it
        print('User profile not found, attempting to create one...');
        await _ensureUserProfileExists(user);
        // Retry after creating profile
        return await getCurrentUser();
      }
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Ensure user profile exists (fallback for signup issues)
  Future<void> _ensureUserProfileExists(User user) async {
    try {
      final username =
          user.userMetadata?['name'] ??
          user.userMetadata?['username'] ??
          'User';

      await _supabase
          .from('user_profiles')
          .insert({
            'id': user.id,
            'username': username,
            'bio': '',
            'books_shared': 0,
            'favorites_count': 0,
            'following_count': 0,
            'followers_count': 0,
          })
          .select()
          .single();
    } catch (e) {
      print('Error creating user profile: $e');
      // Profile might already exist, ignore error
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      // For other users, we can't get their email from auth.users
      // So we'll set email to empty string or handle it gracefully
      final profileData = Map<String, dynamic>.from(response);
      profileData['email'] = ''; // Email not available for other users

      return UserModel.fromJson(profileData);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await _supabase
          .from('user_profiles')
          .update(updates)
          .eq('id', user.id)
          .timeout(const Duration(seconds: 10));

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Get user stats with parallel queries and timeout
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      // Run all queries in parallel with timeout for better performance
      final results = await Future.wait([
        _supabase
            .from('books')
            .select('id')
            .eq('user_id', userId)
            .timeout(const Duration(seconds: 8)),
        _supabase
            .from('user_favorites')
            .select('id')
            .eq('user_id', userId)
            .timeout(const Duration(seconds: 8)),
        _supabase
            .from('user_follows')
            .select('id')
            .eq('follower_id', userId)
            .timeout(const Duration(seconds: 8)),
        _supabase
            .from('user_follows')
            .select('id')
            .eq('following_id', userId)
            .timeout(const Duration(seconds: 8)),
      ]);

      return {
        'books_shared': (results[0] as List).length,
        'favorites': (results[1] as List).length,
        'following': (results[2] as List).length,
        'followers': (results[3] as List).length,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'books_shared': 0,
        'favorites': 0,
        'following': 0,
        'followers': 0,
      };
    }
  }
}
