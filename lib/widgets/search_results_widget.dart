import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/local_book_model.dart';
import '../screens/book_details.dart';
import 'dart:io'; // Added for File

class SearchResultsWidget extends StatelessWidget {
  final List<BookModel> cloudBookResults;
  final List<LocalBookModel> localBookResults;
  final VoidCallback onClose;
  final bool isLoading;

  const SearchResultsWidget({
    super.key,
    required this.cloudBookResults,
    required this.localBookResults,
    required this.onClose,
    this.isLoading = false,
  });

  int get totalResults => cloudBookResults.length + localBookResults.length;

  @override
  Widget build(BuildContext context) {
    final skyBlue = const Color(0xFF87CEEB);
    final sakuraPink = const Color(0xFFFCE4EC);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: skyBlue.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: skyBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Search Results',
                  style: TextStyle(
                    color: skyBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '${totalResults} found',
                  style: TextStyle(
                    color: skyBlue.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close, color: skyBlue, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),

          // Results
          if (isLoading)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  CircularProgressIndicator(color: skyBlue, strokeWidth: 2),
                  const SizedBox(height: 16),
                  Text(
                    'Searching...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            )
          else if (totalResults == 0)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No books found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try different keywords or check spelling',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                if (cloudBookResults.isNotEmpty)
                  _buildResultsSection(
                    context,
                    'Cloud Books',
                    cloudBookResults,
                    skyBlue,
                    sakuraPink,
                  ),
                if (localBookResults.isNotEmpty)
                  _buildLocalResultsSection(
                    context,
                    'Local Books',
                    localBookResults,
                    skyBlue,
                    sakuraPink,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(
    BuildContext context,
    String title,
    List<BookModel> results,
    Color skyBlue,
    Color sakuraPink,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final book = results[index];
              return _buildSearchResultItem(context, book, skyBlue, sakuraPink);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocalResultsSection(
    BuildContext context,
    String title,
    List<LocalBookModel> results,
    Color skyBlue,
    Color sakuraPink,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final book = results[index];
              return _buildLocalSearchResultItem(
                context,
                book,
                skyBlue,
                sakuraPink,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(
    BuildContext context,
    BookModel book,
    Color skyBlue,
    Color sakuraPink,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailPage(
              title: book.title,
              author: book.author,
              genre: book.genre ?? 'Unknown',
              pages: 0, // Not available in current model
              year: book.createdAt.year,
              rating: 0.0, // Not available in current model
              reviews: 0, // Not available in current model
              coverUrl: book.coverUrl ?? '',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: skyBlue.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            // Cover placeholder
            Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(
                color: book.coverUrl != null && book.coverUrl!.isNotEmpty
                    ? Colors.transparent
                    : skyBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: skyBlue.withOpacity(0.3), width: 1),
              ),
              child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.book,
                            color: skyBlue.withOpacity(0.6),
                            size: 24,
                          );
                        },
                      ),
                    )
                  : Icon(Icons.book, color: skyBlue.withOpacity(0.6), size: 24),
            ),
            const SizedBox(width: 12),

            // Book details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book.genre != null && book.genre!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: sakuraPink.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        book.genre!,
                        style: TextStyle(
                          color: sakuraPink.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              color: skyBlue.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalSearchResultItem(
    BuildContext context,
    LocalBookModel book,
    Color skyBlue,
    Color sakuraPink,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to local book reader or details
        // For now, we'll show a placeholder
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${book.title}...'),
            backgroundColor: skyBlue,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: skyBlue.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            // Cover placeholder
            Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(
                color: book.coverPath != null
                    ? Colors.transparent
                    : skyBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: skyBlue.withOpacity(0.3), width: 1),
              ),
              child: book.coverPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(book.coverPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.book,
                            color: skyBlue.withOpacity(0.6),
                            size: 24,
                          );
                        },
                      ),
                    )
                  : Icon(Icons.book, color: skyBlue.withOpacity(0.6), size: 24),
            ),
            const SizedBox(width: 12),

            // Book details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (book.genre != null && book.genre!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: sakuraPink.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        book.genre!,
                        style: TextStyle(
                          color: sakuraPink.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Local Book • ${book.fileExtension.toUpperCase()}',
                    style: TextStyle(
                      color: skyBlue.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              color: skyBlue.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
