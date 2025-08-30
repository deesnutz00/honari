import 'package:flutter/material.dart';
import '../models/book_model.dart';
import 'book_reader_screen.dart';

class BookDetailsScreen extends StatelessWidget {
  final BookModel book;

  const BookDetailsScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final Color skyBlue = const Color(0xFF87CEEB);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              book.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: book.isFavorite ? Colors.red : Colors.grey,
            ),
            onPressed: () {
              // TODO: Add to favorites functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.grey),
            onPressed: () {
              // TODO: Add share functionality
            },
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Book Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover Section
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: (book.firstPageUrl != null)
                      ? Image.network(
                          book.firstPageUrl!,
                          height: 280,
                          width: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultCover(skyBlue);
                          },
                        )
                      : book.coverUrl != null
                          ? Image.network(
                              book.coverUrl!,
                              height: 280,
                              width: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultCover(skyBlue);
                              },
                            )
                          : _buildDefaultCover(skyBlue),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Book Title and Author
            Center(
              child: Column(
                children: [
                  Text(
                    book.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "by ${book.author}",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Book Info Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoChip("Genre", book.genre ?? 'General', skyBlue),
                _infoChip("Added", _formatDate(book.createdAt), skyBlue),
                _infoChip(
                  "Status",
                  book.isFavorite ? 'Favorited' : 'Available',
                  skyBlue,
                ),
              ],
            ),

            if (book.description != null) ...[
              const SizedBox(height: 24),
              // Description Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: skyBlue.withOpacity(
                    0.3,
                  ), // Changed from lightSkyBlue to skyBlue
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: skyBlue.withOpacity(
                      0.5,
                    ), // Changed from lightSkyBlue to skyBlue
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Description",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: skyBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      book.description!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Start Reading Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Check if book has a file URL for reading
                  if (book.bookFileUrl == null || book.bookFileUrl!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Book file not available for reading'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  // Navigate to the cloud book reader
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CloudBookReaderScreen(book: book),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: skyBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Start Reading',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCover(Color skyBlue) {
    return Container(
      height: 280,
      width: 200,
      decoration: BoxDecoration(
        color: skyBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.book, size: 80, color: skyBlue),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
