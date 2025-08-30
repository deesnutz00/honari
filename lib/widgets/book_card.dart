import 'dart:io';

import 'package:flutter/material.dart';
import 'package:honari/screens/book_details.dart';
import 'package:honari/models/book_model.dart';

class BookCard extends StatelessWidget {
  final String title;
  final String author;
  final String genre;
  final int pages;
  final int year;
  final double rating;
  final int reviews;
  final String coverUrl;
  final bool isLocal; // <-- Add this

  const BookCard({
    super.key,
    required this.title,
    required this.author,
    required this.genre,
    required this.pages,
    required this.year,
    required this.rating,
    required this.reviews,
    required this.coverUrl,
    this.isLocal = false, // <-- Add this
  });

  @override
  Widget build(BuildContext context) {
    Widget coverWidget;
    if (isLocal) {
      coverWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(coverUrl),
          height: 180,
          width: 140,
          fit: BoxFit.cover,
        ),
      );
    } else {
      coverWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          coverUrl,
          height: 180,
          width: 140,
          fit: BoxFit.cover,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Create a BookModel for navigation
        final book = BookModel(
          id: 'book_${title.hashCode}',
          title: title,
          author: author,
          genre: genre,
          userId: 'current_user',
          createdAt: DateTime.now(),
          coverUrl: coverUrl,
          bookFileUrl:
              "https://example.com/sample.pdf", // Placeholder URL for demo
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book)),
        );
      },
      child: Container(
        width: 140, // fixed width for horizontal list
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            coverWidget,
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
