import 'package:flutter/material.dart';
import 'package:honari/screens/book_details.dart';

class BookCard extends StatelessWidget {
  final String title;
  final String author;
  final String genre;
  final int pages;
  final int year;
  final double rating;
  final int reviews;
  final String coverUrl;

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
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailPage(
              title: title,
              author: author,
              genre: genre,
              pages: pages,
              year: year,
              rating: rating,
              reviews: reviews,
              coverUrl: coverUrl,
            ),
          ),
        );
      },
      child: Container(
        width: 140, // fixed width for horizontal list
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                coverUrl,
                height: 180,
                width: 140,
                fit: BoxFit.cover,
              ),
            ),
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
