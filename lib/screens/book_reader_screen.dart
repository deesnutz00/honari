import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/local_book_model.dart';
import '../services/local_book_service.dart';
import 'package:path/path.dart' as path;

class BookReaderScreen extends StatefulWidget {
  final LocalBookModel book;
  final LocalBookService localBookService;

  const BookReaderScreen({
    super.key,
    required this.book,
    required this.localBookService,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final Color skyBlue = const Color(0xFF87CEEB);
  bool _isLoading = true;
  String? _errorMessage;
  List<Uint8List> _cbzPages = [];
  int _currentPage = 0;
  double _readingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeReader();
  }

  Future<void> _initializeReader() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      switch (widget.book.fileExtension.toLowerCase()) {
        case 'cbz':
          await _loadCbzPages();
          break;
        case 'pdf':
        case 'epub':
        case 'txt':
          // These will be handled by their respective viewers
          break;
        default:
          setState(() {
            _errorMessage =
                'Unsupported file format: ${widget.book.fileExtension}';
          });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading book: $e';
      });
    }
  }

  Future<void> _loadCbzPages() async {
    try {
      final file = File(widget.book.filePath);
      if (!await file.exists()) {
        throw Exception('Book file not found');
      }

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Extract and sort image files
      final imageFiles = <ArchiveFile>[];
      for (final file in archive) {
        final fileName = file.name.toLowerCase();
        if (fileName.endsWith('.jpg') ||
            fileName.endsWith('.jpeg') ||
            fileName.endsWith('.png') ||
            fileName.endsWith('.gif') ||
            fileName.endsWith('.webp')) {
          imageFiles.add(file);
        }
      }

      // Sort by filename to maintain page order
      imageFiles.sort((a, b) => a.name.compareTo(b.name));

      // Convert to Uint8List for display
      _cbzPages = imageFiles.map((file) => file.content as Uint8List).toList();

      // Update reading progress
      _readingProgress = widget.book.readingProgress ?? 0.0;
      _currentPage = (_readingProgress * _cbzPages.length).round();

      setState(() {});
    } catch (e) {
      throw Exception('Failed to load CBZ pages: $e');
    }
  }

  void _nextPage() {
    if (_currentPage < _cbzPages.length - 1) {
      setState(() {
        _currentPage++;
        _updateReadingProgress();
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _updateReadingProgress();
      });
    }
  }

  void _updateReadingProgress([int? currentPage, int? totalPages]) {
    if (currentPage != null && totalPages != null) {
      // For PDF and other formats that provide page numbers
      _readingProgress = currentPage / totalPages;
      widget.localBookService.updateReadingProgress(
        widget.book.id,
        _readingProgress,
      );
    } else if (_cbzPages.isNotEmpty) {
      // For CBZ format
      _readingProgress = _currentPage / (_cbzPages.length - 1);
      widget.localBookService.updateReadingProgress(
        widget.book.id,
        _readingProgress,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(
          widget.book.title,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (widget.book.isComicBook && _cbzPages.isNotEmpty)
            Text(
              '${_currentPage + 1}/${_cbzPages.length}',
              style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildReaderContent(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildReaderContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeReader,
              style: ElevatedButton.styleFrom(backgroundColor: skyBlue),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    switch (widget.book.fileExtension.toLowerCase()) {
      case 'pdf':
        return _buildPdfReader();
      case 'epub':
        return _buildEpubReader();
      case 'cbz':
        return _buildCbzReader();
      case 'txt':
        return _buildTxtReader();
      default:
        return _buildUnsupportedFormat();
    }
  }

  Widget _buildPdfReader() {
    return SfPdfViewer.file(
      File(widget.book.filePath),
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _isLoading = false;
        });
      },
      onPageChanged: (PdfPageChangedDetails details) {
        // Get total pages from the controller instead since PdfPageChangedDetails doesn't have pageCount
        final totalPages = widget.book.totalPages ?? 1;
        _updateReadingProgress(details.newPageNumber, totalPages);
      },
      initialPageNumber: widget.book.lastReadPage?.toInt() ?? 1,
    );
  }

  Widget _buildEpubReader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 64, color: skyBlue),
          const SizedBox(height: 16),
          Text(
            'EPUB Reader',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to open in EPUB viewer',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _openEpubViewer(),
            style: ElevatedButton.styleFrom(backgroundColor: skyBlue),
            child: const Text('Open EPUB'),
          ),
        ],
      ),
    );
  }

  Widget _buildCbzReader() {
    if (_cbzPages.isEmpty) {
      return const Center(
        child: Text(
          'No pages found',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return GestureDetector(
      onTapUp: (TapUpDetails details) {
        final screenWidth = MediaQuery.of(context).size.width;
        final tapX = details.localPosition.dx;

        if (tapX < screenWidth / 3) {
          _previousPage();
        } else if (tapX > screenWidth * 2 / 3) {
          _nextPage();
        }
        // Middle area does nothing (for zooming in future)
      },
      child: InteractiveViewer(
        child: Image.memory(
          _cbzPages[_currentPage],
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load page ${_currentPage + 1}',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTxtReader() {
    return FutureBuilder<String>(
      future: File(widget.book.filePath).readAsString(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error reading file: ${snapshot.error}',
              style: TextStyle(color: Colors.red[300]),
            ),
          );
        }

        final content = snapshot.data ?? '';
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1.6,
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnsupportedFormat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline, size: 64, color: Colors.orange[300]),
          const SizedBox(height: 16),
          Text(
            'Unsupported Format',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This file format is not supported yet.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    if (!widget.book.isComicBook || _cbzPages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 80,
      color: Colors.black87,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: _currentPage > 0 ? _previousPage : null,
            icon: Icon(
              Icons.skip_previous,
              color: _currentPage > 0 ? skyBlue : Colors.grey,
              size: 32,
            ),
          ),
          IconButton(
            onPressed: _currentPage < _cbzPages.length - 1 ? _nextPage : null,
            icon: Icon(
              Icons.skip_next,
              color: _currentPage < _cbzPages.length - 1
                  ? skyBlue
                  : Colors.grey,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  void _openEpubViewer() {
    // EPUB viewer coming soon
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('EPUB viewer coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    // Save reading progress when leaving
    if (widget.book.isComicBook && _cbzPages.isNotEmpty) {
      _updateReadingProgress();
    }
    super.dispose();
  }
}
