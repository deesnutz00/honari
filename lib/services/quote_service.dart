import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quote_model.dart';

class QuoteService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get a random active quote for the daily quote
  Future<QuoteModel?> getRandomQuote() async {
    try {
      print('💬 QuoteService: Getting random quote from database');

      final response = await _supabase
          .from('quotes')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        print('💬 QuoteService: No active quotes found');
        return null;
      }

      final quotes = (response as List)
          .map((quote) => QuoteModel.fromJson(quote))
          .toList();

      // Return a random quote from the list
      quotes.shuffle();
      final randomQuote = quotes.first;

      print(
        '💬 QuoteService: Selected random quote: "${randomQuote.content}" by ${randomQuote.author}',
      );
      return randomQuote;
    } catch (e) {
      print('❌ QuoteService: Error getting random quote: $e');
      return null;
    }
  }

  // Get all quotes (for admin purposes)
  Future<List<QuoteModel>> getAllQuotes() async {
    try {
      final response = await _supabase
          .from('quotes')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((quote) => QuoteModel.fromJson(quote))
          .toList();
    } catch (e) {
      print('Error getting all quotes: $e');
      return [];
    }
  }

  // Create a new quote
  Future<String> createQuote({
    required String content,
    required String author,
  }) async {
    try {
      print('💬 Creating quote in database:');
      print('   - Content: $content');
      print('   - Author: $author');

      final quoteData = {
        'content': content,
        'author': author,
        'is_active': true,
      };

      final response = await _supabase
          .from('quotes')
          .insert(quoteData)
          .select('id')
          .single();

      print('✅ Quote created successfully with ID: ${response['id']}');
      return response['id'];
    } catch (e) {
      print('❌ Error creating quote: $e');
      throw Exception('Failed to create quote: $e');
    }
  }

  // Update a quote
  Future<bool> updateQuote({
    required String id,
    String? content,
    String? author,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (content != null) updateData['content'] = content;
      if (author != null) updateData['author'] = author;
      if (isActive != null) updateData['is_active'] = isActive;

      if (updateData.isEmpty) return true;

      await _supabase.from('quotes').update(updateData).eq('id', id);

      print('✅ Quote updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating quote: $e');
      return false;
    }
  }

  // Delete a quote
  Future<bool> deleteQuote(String id) async {
    try {
      await _supabase.from('quotes').delete().eq('id', id);

      print('✅ Quote deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting quote: $e');
      return false;
    }
  }

  // Toggle quote active status
  Future<bool> toggleQuoteStatus(String id, bool isActive) async {
    return updateQuote(id: id, isActive: isActive);
  }
}
