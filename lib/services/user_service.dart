import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
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

      await _supabase.from('users').update(updates).eq('id', user.id);

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Get user stats
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      // Get books shared count
      final booksResponse = await _supabase
          .from('books')
          .select('id')
          .eq('user_id', userId);

      // Get favorites count
      final favoritesResponse = await _supabase
          .from('user_favorites')
          .select('id')
          .eq('user_id', userId);

      // Get following count
      final followingResponse = await _supabase
          .from('user_follows')
          .select('id')
          .eq('follower_id', userId);

      // Get followers count
      final followersResponse = await _supabase
          .from('user_follows')
          .select('id')
          .eq('following_id', userId);

      return {
        'books_shared': booksResponse.length,
        'favorites': favoritesResponse.length,
        'following': followingResponse.length,
        'followers': followersResponse.length,
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
