import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/local_book_model.dart';
import '../models/book_model.dart';
import '../services/local_book_service.dart';
import '../services/book_service.dart';
import 'package:path/path.dart' as path;

class CloudBookReaderScreen extends StatefulWidget {
  final BookModel book;

  const CloudBookReaderScreen({super.key, required this.book});

  @override
  State<CloudBookReaderScreen> createState() => _CloudBookReaderScreenState();
}

class _CloudBookReaderScreenState extends State<CloudBookReaderScreen> {
  final Color skyBlue = const Color(0xFF87CEEB);
  final BookService _bookService = BookService();
  bool _isLoading = true;
  String? _errorMessage;
  String? _bookFileUrl;

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

      // Check if book has a file URL for reading
      if (widget.book.bookFileUrl == null || widget.book.bookFileUrl!.isEmpty) {
        // Try to get a signed URL from the service
        if (widget.book.bookFilePath != null) {
          final signedUrl = await _bookService.getBookReadUrl(widget.book.id);
          if (signedUrl != null) {
            _bookFileUrl = signedUrl;
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }

        setState(() {
          _errorMessage = 'Book file not available for reading';
          _isLoading = false;
        });
        return;
      }

      _bookFileUrl = widget.book.bookFileUrl;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.book.title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.grey),
            onPressed: () {
              // TODO: Add bookmark functionality
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Unable to open book',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: skyBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    if (_bookFileUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Book file not available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This book does not have a readable file attached.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Determine file type and show appropriate viewer
    final fileExtension = _getFileExtension(_bookFileUrl!);
    return _buildBookViewer(fileExtension);
  }

  Widget _buildBookViewer(String fileExtension) {
    switch (fileExtension.toLowerCase()) {
      case 'pdf':
        return SfPdfViewer.network(
          _bookFileUrl!,
          canShowPaginationDialog: true,
          canShowScrollHead: true,
          canShowScrollStatus: true,
        );
      case 'epub':
        // For EPUB files, we'll show a placeholder since SfPdfViewer doesn't support EPUB
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.book_outlined, size: 64, color: skyBlue),
              const SizedBox(height: 16),
              Text(
                'EPUB Reader',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'EPUB support coming soon!',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                'File: ${widget.book.title}',
                style: TextStyle(color: skyBlue, fontSize: 12),
              ),
            ],
          ),
        );
      case 'txt':
        // For text files, we'll show a placeholder
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.text_fields, size: 64, color: skyBlue),
              const SizedBox(height: 16),
              Text(
                'Text Reader',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Text file support coming soon!',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        );
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.file_present, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Unsupported Format',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'File format .$fileExtension is not supported yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        );
    }
  }

  String _getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final fileName = pathSegments.last;
        final dotIndex = fileName.lastIndexOf('.');
        if (dotIndex != -1 && dotIndex < fileName.length - 1) {
          return fileName.substring(dotIndex + 1);
        }
      }
    } catch (e) {
      print('Error parsing URL: $e');
    }
    return 'unknown';
  }
}

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
        // Use the book's totalPages property since PdfPageChangedDetails doesn't provide pageCount
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
