import '../models/book_model.dart';
import '../models/local_book_model.dart';
import 'book_service.dart';
import 'local_book_service.dart';

class ComprehensiveSearchService {
  final BookService _bookService = BookService();
  final LocalBookService _localBookService = LocalBookService();

  // Search both local and cloud books
  Future<Map<String, List<dynamic>>> searchAllBooks(String query) async {
    try {
      if (query.trim().isEmpty) {
        return {'cloudBooks': <BookModel>[], 'localBooks': <LocalBookModel>[]};
      }

      // Search both sources concurrently
      final results = await Future.wait([
        _bookService.searchBooks(query),
        _localBookService.searchLocalBooks(query),
      ]);

      return {
        'cloudBooks': results[0] as List<BookModel>,
        'localBooks': results[1] as List<LocalBookModel>,
      };
    } catch (e) {
      print('Error in comprehensive search: $e');
      return {'cloudBooks': <BookModel>[], 'localBooks': <LocalBookModel>[]};
    }
  }

  // Get total search result count
  Future<int> getTotalSearchCount(String query) async {
    try {
      final results = await searchAllBooks(query);
      return (results['cloudBooks']?.length ?? 0) +
          (results['localBooks']?.length ?? 0);
    } catch (e) {
      return 0;
    }
  }

  // Search with filters (cloud only, local only, or both)
  Future<Map<String, List<dynamic>>> searchWithFilters(
    String query, {
    bool includeCloud = true,
    bool includeLocal = true,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return {'cloudBooks': <BookModel>[], 'localBooks': <LocalBookModel>[]};
      }

      Map<String, List<dynamic>> results = {
        'cloudBooks': <BookModel>[],
        'localBooks': <LocalBookModel>[],
      };

      if (includeCloud) {
        results['cloudBooks'] = await _bookService.searchBooks(query);
      }

      if (includeLocal) {
        results['localBooks'] = await _localBookService.searchLocalBooks(query);
      }

      return results;
    } catch (e) {
      print('Error in filtered search: $e');
      return {'cloudBooks': <BookModel>[], 'localBooks': <LocalBookModel>[]};
    }
  }

  // Get search suggestions based on existing books
  Future<List<String>> getSearchSuggestions() async {
    try {
      final suggestions = <String>{};

      // Get cloud books for suggestions
      final cloudBooks = await _bookService.getAllBooks();
      for (final book in cloudBooks.take(10)) {
        suggestions.add(book.title);
        suggestions.add(book.author);
        if (book.genre != null && book.genre!.isNotEmpty) {
          suggestions.add(book.genre!);
        }
      }

      // Get local books for suggestions
      final localBooks = await _localBookService.getLocalBooks();
      for (final book in localBooks.take(10)) {
        suggestions.add(book.title);
        suggestions.add(book.author);
        if (book.genre != null && book.genre!.isNotEmpty) {
          suggestions.add(book.genre!);
        }
      }

      return suggestions.toList()..sort();
    } catch (e) {
      print('Error getting search suggestions: $e');
      return [];
    }
  }

  // Get trending search terms (based on recent uploads)
  Future<List<String>> getTrendingSearchTerms() async {
    try {
      final trending = <String>[];

      // Get recent cloud books
      final recentCloudBooks = await _bookService.getAllBooks();
      for (final book in recentCloudBooks.take(5)) {
        if (book.genre != null && book.genre!.isNotEmpty) {
          trending.add(book.genre!);
        }
      }

      // Get recent local books
      final recentLocalBooks = await _localBookService.getLocalBooks();
      for (final book in recentLocalBooks.take(5)) {
        if (book.genre != null && book.genre!.isNotEmpty) {
          trending.add(book.genre!);
        }
      }

      // Remove duplicates and return
      return trending.toSet().toList();
    } catch (e) {
      print('Error getting trending search terms: $e');
      return [];
    }
  }
}
