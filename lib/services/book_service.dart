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

      return (response as List)
          .map((book) => BookModel.fromJson(book))
          .toList();
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

      return (booksResponse as List)
          .map((book) => BookModel.fromJson(book))
          .toList();
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

      return (response as List)
          .map((book) => BookModel.fromJson(book))
          .toList();
    } catch (e) {
      print('Error getting all books: $e');
      return [];
    }
  }

  // Add book to favorites
  Future<bool> addToFavorites(String userId, String bookId) async {
    try {
      await _supabase.from('user_favorites').insert({
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

  // Create a new book
  Future<String> createBook({
    required String title,
    required String author,
    required String userId,
    String? description,
    String? genre,
    String? coverUrl,
  }) async {
    try {
      print('📚 Creating book in database:');
      print('   - Title: $title');
      print('   - Author: $author');
      print('   - User ID: $userId');
      print('   - Genre: $genre');
      print('   - Cover URL: $coverUrl');

      final bookData = {
        'title': title,
        'author': author,
        'description': description ?? '',
        'genre': genre ?? '',
        'cover_url': coverUrl,
        'user_id': userId,
      };

      print('📚 Book data to insert: $bookData');

      final response = await _supabase
          .from('books')
          .insert(bookData)
          .select('id')
          .single();

      print('✅ Book created successfully with ID: ${response['id']}');
      return response['id'];
    } catch (e) {
      print('❌ Error creating book: $e');
      print('❌ Error details: ${e.toString()}');
      throw Exception('Failed to create book: $e');
    }
  }

  // Search books by title, author, or genre
  Future<List<BookModel>> searchBooks(String query) async {
    try {
      print('🔍 Searching for: "$query"');

      if (query.trim().isEmpty) {
        print('❌ Empty query, returning empty results');
        return [];
      }

      final searchQuery = query.trim().toLowerCase();
      print('🔍 Processed search query: "$searchQuery"');

      // First, let's check if there are any books at all
      final allBooksResponse = await _supabase.from('books').select().limit(5);

      print('📚 Total books in database: ${allBooksResponse.length}');
      if (allBooksResponse.isNotEmpty) {
        print('📚 Sample book: ${allBooksResponse.first}');
      }

      // Search in title, author, and genre fields
      final response = await _supabase
          .from('books')
          .select()
          .or(
            'title.ilike.%$searchQuery%,author.ilike.%$searchQuery%,genre.ilike.%$searchQuery%',
          )
          .order('created_at', ascending: false)
          .limit(20);

      print('🔍 Search results found: ${response.length}');

      final results = (response as List)
          .map((book) => BookModel.fromJson(book))
          .toList();

      print('✅ Search completed successfully');
      return results;
    } catch (e) {
      print('❌ Error searching books: $e');
      return [];
    }
  }

  // Get books by genre
  Future<List<BookModel>> getBooksByGenre(String genre) async {
    try {
      final response = await _supabase
          .from('books')
          .select()
          .eq('genre', genre)
          .order('created_at', ascending: false);

      return (response as List)
          .map((book) => BookModel.fromJson(book))
          .toList();
    } catch (e) {
      print('Error getting books by genre: $e');
      return [];
    }
  }

  // Get signed URL for reading a book from storage
  Future<String?> getBookReadUrl(String bookId) async {
    try {
      // First get the book to find the file path
      final response = await _supabase
          .from('books')
          .select('book_file_path')
          .eq('id', bookId)
          .single();

      if (response['book_file_path'] == null) {
        return null;
      }

      final filePath = response['book_file_path'] as String;

      // Get a signed URL for reading the file
      final signedUrl = await _supabase.storage
          .from('books')
          .createSignedUrl(filePath, 3600); // 1 hour expiry

      return signedUrl;
    } catch (e) {
      print('Error getting book read URL: $e');
      return null;
    }
  }

  // Update book with file information after upload
  Future<bool> updateBookFile(
    String bookId,
    String filePath,
    String fileUrl,
  ) async {
    try {
      await _supabase
          .from('books')
          .update({'book_file_path': filePath, 'book_file_url': fileUrl})
          .eq('id', bookId);

      return true;
    } catch (e) {
      print('Error updating book file: $e');
      return false;
    }
  }
}
