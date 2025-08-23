import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book_model.dart';

class BookService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get user's books
  Future<List<BookModel>> getUserBooks(String userId) async {
    try {
      final response = await _supabase
          .from('books')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((book) => BookModel.fromJson(book)).toList();
    } catch (e) {
      print('Error getting user books: $e');
      return [];
    }
  }

  // Get user's favorite books
  Future<List<BookModel>> getUserFavorites(String userId) async {
    try {
      final response = await _supabase
          .from('user_favorites')
          .select('book_id')
          .eq('user_id', userId);

      if (response.isEmpty) return [];

      final bookIds = (response as List).map((fav) => fav['book_id']).toList();
      
      final booksResponse = await _supabase
          .from('books')
          .select()
          .inFilter('id', bookIds)
          .order('created_at', ascending: false);

      return (booksResponse as List).map((book) => BookModel.fromJson(book)).toList();
    } catch (e) {
      print('Error getting user favorites: $e');
      return [];
    }
  }

  // Get all books for library
  Future<List<BookModel>> getAllBooks() async {
    try {
      final response = await _supabase
          .from('books')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((book) => BookModel.fromJson(book)).toList();
    } catch (e) {
      print('Error getting all books: $e');
      return [];
    }
  }

  // Add book to favorites
  Future<bool> addToFavorites(String userId, String bookId) async {
    try {
      await _supabase
          .from('user_favorites')
          .insert({
            'user_id': userId,
            'book_id': bookId,
          });

      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  // Remove book from favorites
  Future<bool> removeFromFavorites(String userId, String bookId) async {
    try {
      await _supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('book_id', bookId);

      return true;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  // Check if book is in favorites
  Future<bool> isBookFavorite(String userId, String bookId) async {
    try {
      final response = await _supabase
          .from('user_favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('book_id', bookId)
          .single();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}
