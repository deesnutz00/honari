import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import '../models/local_book_model.dart';

class LocalBookService {
  static const String _booksKey = 'local_books';
  static const String _booksDirectory = 'books';
  static const String _coversDirectory = 'covers';

  // Get local books from storage
  Future<List<LocalBookModel>> getLocalBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getStringList(_booksKey) ?? [];

      List<LocalBookModel> books = [];
      for (String bookJson in booksJson) {
        try {
          final Map<String, dynamic> bookMap = {};
          final parts = bookJson.split('|||');
          
          for (final part in parts) {
            final keyValue = part.split('::');
            if (keyValue.length >= 2) {
              final key = keyValue[0];
              final value = keyValue[1];
              
              // Convert string values to appropriate types
              if (key == 'fileSizeBytes' || key == 'totalPages') {
                bookMap[key] = int.tryParse(value) ?? 0;
              } else if (key == 'readingProgress') {
                bookMap[key] = double.tryParse(value) ?? 0.0;
              } else {
                bookMap[key] = value;
              }
            }
          }
          
          final book = LocalBookModel.fromJson(bookMap);
          books.add(book);
        } catch (e) {
          print('Error parsing book: $e');
        }
      }

      // Sort by last opened (most recent first)
      books.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
      return books;
    } catch (e) {
      print('Error getting local books: $e');
      return [];
    }
  }

  // Add a new local book
  Future<bool> addLocalBook(File file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/$_booksDirectory');
      final coversDir = Directory('${appDir.path}/$_coversDirectory');

      // Create directories if they don't exist
      if (!await booksDir.exists()) await booksDir.create(recursive: true);
      if (!await coversDir.exists()) await coversDir.create(recursive: true);

      // Generate unique filename
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      final newFileName = '${uniqueId}_$fileName';
      final newFilePath = '${booksDir.path}/$newFileName';

      // Copy file to app directory
      await file.copy(newFilePath);

      // Extract metadata and cover
      final metadata = await _extractBookMetadata(newFilePath, fileExtension);
      final coverPath = await _extractCover(
        newFilePath,
        fileExtension,
        coversDir.path,
        uniqueId,
      );

      // Create book model
      final book = LocalBookModel(
        id: uniqueId,
        title: metadata['title'] ?? _extractTitleFromFileName(fileName),
        author: metadata['author'] ?? 'Unknown Author',
        genre: metadata['genre'] ?? _getGenreFromExtension(fileExtension),
        filePath: newFilePath,
        fileName: newFileName,
        fileExtension: fileExtension,
        fileSizeBytes: await file.length(),
        lastOpened: DateTime.now(),
        addedDate: DateTime.now(),
        coverPath: coverPath,
        totalPages: metadata['totalPages'],
        readingProgress: 0.0,
      );

      // Save to storage
      await _saveBook(book);

      return true;
    } catch (e) {
      print('Error adding local book: $e');
      return false;
    }
  }

  // Update book metadata
  Future<bool> updateBook(LocalBookModel book) async {
    try {
      await _saveBook(book);
      return true;
    } catch (e) {
      print('Error updating book: $e');
      return false;
    }
  }

  // Delete a local book
  Future<bool> deleteBook(LocalBookModel book) async {
    try {
      // Remove file
      final file = File(book.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove cover
      if (book.coverPath != null) {
        final coverFile = File(book.coverPath!);
        if (await coverFile.exists()) {
          await coverFile.delete();
        }
      }

      // Remove from storage
      await _removeBook(book.id);

      return true;
    } catch (e) {
      print('Error deleting book: $e');
      return false;
    }
  }

  // Update reading progress
  Future<bool> updateReadingProgress(String bookId, double progress) async {
    try {
      final books = await getLocalBooks();
      final bookIndex = books.indexWhere((b) => b.id == bookId);

      if (bookIndex != -1) {
        final updatedBook = books[bookIndex].copyWith(
          readingProgress: progress,
          lastOpened: DateTime.now(),
        );
        books[bookIndex] = updatedBook;
        await _saveBooks(books);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating reading progress: $e');
      return false;
    }
  }

  // Update last opened time
  Future<bool> updateLastOpenedTime(String bookId) async {
    try {
      final books = await getLocalBooks();
      final bookIndex = books.indexWhere((b) => b.id == bookId);

      if (bookIndex != -1) {
        final updatedBook = books[bookIndex].copyWith(
          lastOpened: DateTime.now(),
        );
        books[bookIndex] = updatedBook;
        await _saveBooks(books);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating last opened time: $e');
      return false;
    }
  }

  // Extract book metadata based on file type
  Future<Map<String, dynamic>> _extractBookMetadata(
    String filePath,
    String extension,
  ) async {
    try {
      switch (extension.toLowerCase()) {
        case 'pdf':
          return await _extractPdfMetadata(filePath);
        case 'epub':
          return await _extractEpubMetadata(filePath);
        case 'cbz':
          return await _extractCbzMetadata(filePath);
        case 'txt':
          return await _extractTxtMetadata(filePath);
        default:
          return {};
      }
    } catch (e) {
      print('Error extracting metadata: $e');
      return {};
    }
  }

  // Extract PDF metadata
  Future<Map<String, dynamic>> _extractPdfMetadata(String filePath) async {
    return {
      'title': _extractTitleFromFileName(filePath.split('/').last),
      'author': 'Unknown Author',
      'genre': 'Document',
      'totalPages': null,
    };
  }

  // Extract EPUB metadata
  Future<Map<String, dynamic>> _extractEpubMetadata(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final containerFile = archive.findFile('META-INF/container.xml');
      if (containerFile != null) {
        final containerContent = String.fromCharCodes(
          containerFile.content as List<int>,
        );
        return {
          'title': _extractTitleFromFileName(filePath.split('/').last),
          'author': 'Unknown Author',
          'genre': 'E-Book',
          'totalPages': null,
        };
      }
    } catch (e) {
      print('Error extracting EPUB metadata: $e');
    }

    return {
      'title': _extractTitleFromFileName(filePath.split('/').last),
      'author': 'Unknown Author',
      'genre': 'E-Book',
      'totalPages': null,
    };
  }

  // Extract CBZ metadata
  Future<Map<String, dynamic>> _extractCbzMetadata(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      int imageCount = 0;
      for (final file in archive) {
        final fileName = file.name.toLowerCase();
        if (fileName.endsWith('.jpg') ||
            fileName.endsWith('.jpeg') ||
            fileName.endsWith('.png') ||
            fileName.endsWith('.gif') ||
            fileName.endsWith('.webp')) {
          imageCount++;
        }
      }

      return {
        'title': _extractTitleFromFileName(filePath.split('/').last),
        'author': 'Unknown Author',
        'genre': 'Comic Book',
        'totalPages': imageCount,
      };
    } catch (e) {
      print('Error extracting CBZ metadata: $e');
      return {
        'title': _extractTitleFromFileName(filePath.split('/').last),
        'author': 'Unknown Author',
        'genre': 'Comic Book',
        'totalPages': null,
      };
    }
  }

  // Extract TXT metadata
  Future<Map<String, dynamic>> _extractTxtMetadata(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final lines = content.split('\n');

      return {
        'title': _extractTitleFromFileName(filePath.split('/').last),
        'author': 'Unknown Author',
        'genre': 'Text',
        'totalPages': (content.length / 2000).ceil(),
      };
    } catch (e) {
      print('Error extracting TXT metadata: $e');
      return {
        'title': _extractTitleFromFileName(filePath.split('/').last),
        'author': 'Unknown Author',
        'genre': 'Text',
        'totalPages': null,
      };
    }
  }

  // Extract cover image from book
  Future<String?> _extractCover(
    String filePath,
    String extension,
    String coversDir,
    String bookId,
  ) async {
    try {
      switch (extension.toLowerCase()) {
        case 'cbz':
          return await _extractCbzCover(filePath, coversDir, bookId);
        case 'epub':
          return await _extractEpubCover(filePath, coversDir, bookId);
        case 'pdf':
          return await _extractPdfCover(filePath, coversDir, bookId);
        default:
          return null;
      }
    } catch (e) {
      print('Error extracting cover: $e');
      return null;
    }
  }

  // Extract cover from CBZ file
  Future<String?> _extractCbzCover(
    String filePath,
    String coversDir,
    String bookId,
  ) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? coverFile;
      for (final file in archive) {
        final fileName = file.name.toLowerCase();
        if (fileName.endsWith('.jpg') ||
            fileName.endsWith('.jpeg') ||
            fileName.endsWith('.png')) {
          coverFile = file;
          break;
        }
      }

      if (coverFile != null) {
        final coverPath = '$coversDir/${bookId}_cover.jpg';
        final coverBytes = coverFile.content as List<int>;

        final image = img.decodeImage(
          Uint8List.fromList(coverBytes),
        ); // ✅ FIXED
        if (image != null) {
          final resized = img.copyResize(image, width: 300, height: 400);
          final resizedBytes = img.encodeJpg(resized, quality: 85);
          await File(coverPath).writeAsBytes(resizedBytes);
          return coverPath;
        }
      }

      return null;
    } catch (e) {
      print('Error extracting CBZ cover: $e');
      return null;
    }
  }

  // Extract cover from EPUB file
  Future<String?> _extractEpubCover(
    String filePath,
    String coversDir,
    String bookId,
  ) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? coverFile;
      for (final file in archive) {
        final fileName = file.name.toLowerCase();
        if (fileName.contains('cover') &&
            (fileName.endsWith('.jpg') ||
                fileName.endsWith('.jpeg') ||
                fileName.endsWith('.png'))) {
          coverFile = file;
          break;
        }
      }

      if (coverFile != null) {
        final coverPath = '$coversDir/${bookId}_cover.jpg';
        final coverBytes = coverFile.content as List<int>;

        final image = img.decodeImage(
          Uint8List.fromList(coverBytes),
        ); // ✅ FIXED
        if (image != null) {
          final resized = img.copyResize(image, width: 300, height: 400);
          final resizedBytes = img.encodeJpg(resized, quality: 85);
          await File(coverPath).writeAsBytes(resizedBytes);
          return coverPath;
        }
      }

      return null;
    } catch (e) {
      print('Error extracting EPUB cover: $e');
      return null;
    }
  }

  // Extract cover from PDF file
  Future<String?> _extractPdfCover(
    String filePath,
    String coversDir,
    String bookId,
  ) async {
    try {
      final coverPath = '$coversDir/${bookId}_cover.jpg';
      
      // Create a placeholder cover for PDF files
      // This is a temporary solution until we can properly render PDF pages
      final canvas = ui.PictureRecorder();
      final paint = Paint()
        ..color = Colors.white;
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'PDF',
          style: TextStyle(color: Colors.black, fontSize: 40, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      final pictureCanvas = Canvas(canvas);
      pictureCanvas.drawRect(Rect.fromLTWH(0, 0, 300, 400), paint);
      
      // Draw a PDF icon
      paint.color = Colors.red;
      pictureCanvas.drawRect(Rect.fromLTWH(75, 100, 150, 200), paint);
      
      // Draw text in the center
      textPainter.paint(
        pictureCanvas, 
        Offset(
          150 - textPainter.width / 2,
          200 - textPainter.height / 2,
        ),
      );
      
      final picture = canvas.endRecording();
      final img = await picture.toImage(300, 400);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        await File(coverPath).writeAsBytes(byteData.buffer.asUint8List());
        return coverPath;
      }
      
      return null;
    } catch (e) {
      print('Error extracting PDF cover: $e');
      return null;
    }
  }

  // Helper methods
  String _extractTitleFromFileName(String fileName) {
    final nameWithoutExt = fileName.split('.').first;
    return nameWithoutExt.replaceAll('_', ' ').replaceAll('-', ' ');
  }

  String _getGenreFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'Document';
      case 'epub':
        return 'E-Book';
      case 'cbz':
        return 'Comic Book';
      case 'txt':
        return 'Text';
      default:
        return 'Other';
    }
  }

  Future<void> _saveBook(LocalBookModel book) async {
    final books = await getLocalBooks();
    final existingIndex = books.indexWhere((b) => b.id == book.id);

    if (existingIndex != -1) {
      books[existingIndex] = book;
    } else {
      books.add(book);
    }

    await _saveBooks(books);
  }

  Future<void> _saveBooks(List<LocalBookModel> books) async {
    final prefs = await SharedPreferences.getInstance();
    final booksJson = books.map((book) {
      final json = book.toJson();
      return json.entries.map((e) => '${e.key}::${e.value}').join('|||');
    }).toList();

    await prefs.setStringList(_booksKey, booksJson);
  }

  Future<void> _removeBook(String bookId) async {
    final books = await getLocalBooks();
    books.removeWhere((b) => b.id == bookId);
    await _saveBooks(books);
  }

  Future<String> getAppDocumentsPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return appDir.path;
  }

  Future<String> getBooksDirectoryPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$_booksDirectory';
  }

  Future<String> getCoversDirectoryPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$_coversDirectory';
  }
}
