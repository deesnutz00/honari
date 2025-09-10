import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/like_model.dart';

class LikeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Add a like to a book
  Future<bool> addLike(String bookId, String userId) async {
    try {
      await _supabase.from('book_likes').insert({
        'book_id': bookId,
        'user_id': userId,
      });
      return true;
    } catch (e) {
      print('Error adding like: $e');
      return false;
    }
  }

  // Remove a like from a book
  Future<bool> removeLike(String bookId, String userId) async {
    try {
      await _supabase
          .from('book_likes')
          .delete()
          .eq('book_id', bookId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error removing like: $e');
      return false;
    }
  }

  // Check if a user has liked a book
  Future<bool> hasUserLikedBook(String bookId, String userId) async {
    try {
      final response = await _supabase
          .from('book_likes')
          .select('id')
          .eq('book_id', bookId)
          .eq('user_id', userId)
          .single();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Get like count for a book
  Future<int> getLikeCount(String bookId) async {
    try {
      final response = await _supabase
          .from('book_likes')
          .select('id')
          .eq('book_id', bookId);

      return (response as List).length;
    } catch (e) {
      print('Error getting like count: $e');
      return 0;
    }
  }

  // Toggle like for a book
  Future<bool> toggleLike(String bookId, String userId) async {
    try {
      final hasLiked = await hasUserLikedBook(bookId, userId);

      if (hasLiked) {
        return await removeLike(bookId, userId);
      } else {
        return await addLike(bookId, userId);
      }
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  // Get user's liked books
  Future<List<String>> getUserLikedBookIds(String userId) async {
    try {
      final response = await _supabase
          .from('book_likes')
          .select('book_id')
          .eq('user_id', userId);

      return (response as List)
          .map((like) => like['book_id'] as String)
          .toList();
    } catch (e) {
      print('Error getting user liked books: $e');
      return [];
    }
  }
}
