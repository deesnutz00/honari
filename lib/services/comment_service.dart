import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';

class CommentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get comments for a specific post
  Future<List<CommentModel>> getCommentsForPost(String postId) async {
    try {
      final response = await _supabase
          .from('post_comments')
          .select('*, user_profiles(username, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (response as List).map((comment) {
        final commentJson = Map<String, dynamic>.from(comment);
        // Merge user profile data
        if (comment['user_profiles'] != null) {
          commentJson['username'] =
              comment['user_profiles']['username'] ?? 'Anonymous';
          commentJson['avatar_url'] = comment['user_profiles']['avatar_url'];
        }
        return CommentModel.fromJson(commentJson);
      }).toList();
    } catch (e) {
      print('Error getting comments for post: $e');
      return [];
    }
  }

  // Add a comment to a post
  Future<bool> addComment(String postId, String userId, String content) async {
    try {
      await _supabase.from('post_comments').insert({
        'post_id': postId,
        'user_id': userId,
        'content': content.trim(),
      });
      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  // Delete a comment
  Future<bool> deleteComment(String commentId, String userId) async {
    try {
      await _supabase
          .from('post_comments')
          .delete()
          .eq('id', commentId)
          .eq(
            'user_id',
            userId,
          ); // Ensure user can only delete their own comments
      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  // Get comment count for a post
  Future<int> getCommentCount(String postId) async {
    try {
      final response = await _supabase
          .from('post_comments')
          .select('id')
          .eq('post_id', postId);

      return (response as List).length;
    } catch (e) {
      print('Error getting comment count: $e');
      return 0;
    }
  }
}
