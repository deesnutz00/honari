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
      print('📚 BookService: Getting all books from database');

      // Check authentication status
      final user = _supabase.auth.currentUser;
      print('📚 BookService: Current user: ${user?.id ?? "Not authenticated"}');

      final response = await _supabase
          .from('books')
          .select()
          .order('created_at', ascending: false);

      print('📚 BookService: Raw response length: ${response.length}');

      if (response.isNotEmpty) {
        print('📚 BookService: First book sample: ${response.first}');
      } else {
        print('📚 BookService: No books found in response');
        // Try to check if there are any books at all (bypass RLS for debugging)
        try {
          final allBooksCheck = await _supabase.rpc('get_all_books_debug');
          print('📚 BookService: Debug RPC result: $allBooksCheck');
        } catch (debugError) {
          print('📚 BookService: Debug RPC failed: $debugError');
        }
      }

      final books = (response as List)
          .map((book) => BookModel.fromJson(book))
          .toList();

      print('📚 BookService: Successfully parsed ${books.length} books');

      return books;
    } catch (e) {
      print('❌ BookService: Error getting all books: $e');
      print('❌ BookService: Error details: ${e.toString()}');

      // If it's an auth error, try to provide more specific guidance
      if (e.toString().contains('JWT') || e.toString().contains('auth')) {
        print('❌ BookService: This appears to be an authentication issue');
      }

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
    String? bookFileUrl,
  }) async {
    try {
      print('📚 Creating book in database:');
      print('   - Title: $title');
      print('   - Author: $author');
      print('   - User ID: $userId');
      print('   - Genre: $genre');
      print('   - Cover URL: $coverUrl');
      print('   - Book File URL: $bookFileUrl');

      final bookData = {
        'title': title,
        'author': author,
        'description': description ?? '',
        'genre': genre ?? '',
        'cover_url': coverUrl,
        'book_file_url': bookFileUrl,
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
      print('BookService: Getting read URL for book ID: $bookId');

      // Get the book to find the file path
      final response = await _supabase
          .from('books')
          .select('book_file_path, book_file_url')
          .eq('id', bookId)
          .single();

      print('BookService: Database response: $response');

      // Always try to create a fresh signed URL from the file path for security
      if (response['book_file_path'] != null &&
          response['book_file_path'].toString().isNotEmpty) {
        final filePath = response['book_file_path'] as String;
        print('BookService: Creating fresh signed URL for path: $filePath');

        // Clean the path if it has bucket prefix
        String cleanPath = filePath;
        if (filePath.startsWith('books/')) {
          cleanPath = filePath.substring(6); // Remove 'books/' prefix
        }

        print('BookService: Clean path: $cleanPath');

        // Get a fresh signed URL for reading the file (1 hour expiry)
        final signedUrl = await _supabase.storage
            .from('books')
            .createSignedUrl(cleanPath, 3600);

        print('BookService: Generated fresh signed URL: $signedUrl');
        return signedUrl;
      }

      // Fallback: if no file path but we have a stored URL, try to refresh it
      if (response['book_file_url'] != null &&
          response['book_file_url'].toString().isNotEmpty) {
        final storedUrl = response['book_file_url'] as String;
        print('BookService: Found stored URL: $storedUrl');

        // Always generate a fresh signed URL instead of using stored ones
        // This ensures the URL is always valid
        try {
          // Try to extract the file path from various URL formats
          String filePath = '';

          if (storedUrl.contains('/storage/v1/object/sign/')) {
            // Signed URL format: extract the path part
            final uri = Uri.parse(storedUrl);
            final pathParts = uri.path.split('/storage/v1/object/sign/');
            if (pathParts.length > 1) {
              filePath = pathParts[1].split('?')[0]; // Remove query parameters
            }
          } else if (storedUrl.contains('/storage/v1/object/public/')) {
            // Public URL format: extract the path part
            final uri = Uri.parse(storedUrl);
            final pathParts = uri.path.split('/storage/v1/object/public/');
            if (pathParts.length > 1) {
              filePath = pathParts[1];
            }
          }

          if (filePath.isNotEmpty) {
            print('BookService: Extracted file path from URL: $filePath');

            // Clean the path
            if (filePath.startsWith('books/')) {
              filePath = filePath.substring(6);
            }

            final signedUrl = await _supabase.storage
                .from('books')
                .createSignedUrl(filePath, 3600);

            print(
              'BookService: Generated fresh signed URL from stored URL: $signedUrl',
            );
            return signedUrl;
          }
        } catch (e) {
          print('BookService: Could not extract path from stored URL: $e');
        }

        // If we can't extract the path, return the stored URL as last resort
        print('BookService: Returning stored URL as fallback');
        return storedUrl;
      }

      print('BookService: No file path or URL found in database');
      return null;
    } catch (e) {
      print('BookService: Error getting book read URL: $e');
      print('BookService: Error details: ${e.toString()}');
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
      print('BookService: Updating book file for ID: $bookId');
      print('BookService: File path: $filePath');
      print('BookService: File URL: $fileUrl');

      // Store both the path (for signed URL generation) and URL (as backup)
      final updateData = {'book_file_path': filePath, 'book_file_url': fileUrl};

      print('BookService: Update data: $updateData');

      await _supabase.from('books').update(updateData).eq('id', bookId);

      print('BookService: Book file updated successfully');
      return true;
    } catch (e) {
      print('BookService: Error updating book file: $e');
      return false;
    }
  }

  // Helper method to generate a proper signed URL for a file path
  Future<String?> generateSignedUrl(String filePath) async {
    try {
      print('BookService: Generating signed URL for: $filePath');

      // Ensure the file path doesn't include the bucket name prefix
      String cleanPath = filePath;
      if (filePath.startsWith('books/')) {
        cleanPath = filePath.substring(6); // Remove 'books/' prefix
      }

      print('BookService: Clean path for signed URL: $cleanPath');

      final signedUrl = await _supabase.storage
          .from('books')
          .createSignedUrl(cleanPath, 3600); // 1 hour expiry

      print('BookService: Generated signed URL: $signedUrl');
      return signedUrl;
    } catch (e) {
      print('BookService: Error generating signed URL: $e');
      return null;
    }
  }
}
