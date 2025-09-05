import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/local_book_model.dart';
import '../models/book_model.dart';
import '../services/local_book_service.dart';
import '../services/book_service.dart';

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

  // CBZ specific state
  List<Uint8List> _cbzPages = [];
  int _currentPage = 0;

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

      print('Book Reader: Initializing reader for book: ${widget.book.title}');
      print('Book Reader: Book ID: ${widget.book.id}');
      print('Book Reader: Book file URL: ${widget.book.bookFileUrl}');
      print('Book Reader: Book file path: ${widget.book.bookFilePath}');

      // Check if book has a file URL for reading
      if (widget.book.bookFileUrl == null || widget.book.bookFileUrl!.isEmpty) {
        print('Book Reader: No direct file URL, trying to get signed URL');
        // Try to get a signed URL from the service
        if (widget.book.bookFilePath != null) {
          print(
            'Book Reader: Requesting signed URL for path: ${widget.book.bookFilePath}',
          );
          final signedUrl = await _bookService.getBookReadUrl(widget.book.id);
          if (signedUrl != null) {
            print('Book Reader: Got signed URL: $signedUrl');
            _bookFileUrl = signedUrl;
            setState(() {
              _isLoading = false;
            });
            return;
          } else {
            print('Book Reader: Failed to get signed URL');
          }
        } else {
          print(
            'Book Reader: No file path available for signed URL generation',
          );
        }

        setState(() {
          _errorMessage = 'Book file not available for reading';
          _isLoading = false;
        });
        return;
      }

      _bookFileUrl = widget.book.bookFileUrl;
      print('Book Reader: Using direct file URL: $_bookFileUrl');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Book Reader: Error during initialization: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading book: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // For CBZ files, we need full screen control
    final fileExtension = _bookFileUrl != null
        ? _getFileExtension(_bookFileUrl!)
        : '';

    if (fileExtension == 'cbz' && _cbzPages.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(),
        body: _buildCbzContent(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFCE4EC)),
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

  PreferredSizeWidget _buildAppBar() {
    final fileExtension = _bookFileUrl != null
        ? _getFileExtension(_bookFileUrl!)
        : '';

    return AppBar(
      backgroundColor: fileExtension == 'cbz' ? Colors.black87 : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: fileExtension == 'cbz' ? Colors.white : Colors.black87,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.book.title,
        style: TextStyle(
          color: fileExtension == 'cbz' ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (fileExtension == 'cbz' && _cbzPages.isNotEmpty)
          Text(
            '${_currentPage + 1}/${_cbzPages.length}',
            style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold),
          ),
        if (fileExtension != 'cbz')
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.grey),
            onPressed: () {
              // TODO: Add bookmark functionality
            },
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBookViewer(String fileExtension) {
    switch (fileExtension.toLowerCase()) {
      case 'pdf':
        return _buildPdfViewer();
      case 'epub':
        return _buildEpubViewer();
      case 'txt':
        return _buildTxtViewer();
      case 'cbz':
        return _buildCbzViewer();
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

  Widget _buildPdfViewer() {
    print('PDF Viewer: Attempting to load PDF from URL: $_bookFileUrl');

    return FutureBuilder<Uint8List?>(
      future: _downloadPdfBytes(_bookFileUrl!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: skyBlue),
                const SizedBox(height: 16),
                Text(
                  'Downloading PDF...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          print('PDF Viewer: Download failed: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'PDF Reader',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unable to download PDF file',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error ?? "Unknown error"}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[400], fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _retryPdfLoad(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: skyBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        print('PDF Viewer: PDF downloaded successfully, loading viewer');
        return SfPdfViewer.memory(
          snapshot.data!,
          canShowPaginationDialog: true,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            print(
              'PDF Viewer: Document loaded successfully with ${details.document.pages.count} pages',
            );
          },
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            print('PDF Viewer: Document load failed: ${details.description}');
            setState(() {
              _errorMessage = 'Failed to load PDF: ${details.description}';
            });
          },
        );
      },
    );
  }

  Future<Uint8List?> _downloadPdfBytes(String url) async {
    try {
      print('PDF Viewer: Downloading PDF from URL: $url');

      // Create authenticated request for Supabase storage
      final headers = <String, String>{};
      final supabase = Supabase.instance.client;

      // Add authorization header if user is authenticated
      final session = supabase.auth.currentSession;
      if (session != null && session.accessToken != null) {
        headers['Authorization'] = 'Bearer ${session.accessToken}';
        print('PDF Viewer: Added authentication header');
      } else {
        print('PDF Viewer: No authentication session found');
      }

      // Add API key as fallback
      headers['apikey'] =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlyaXl0dXllYW14emN4eXF0YmdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE1NjM3NDgsImV4cCI6MjA2NzEzOTc0OH0.5Coq1Mhj1BMcDLJchHOjk35N8BASkU3NmHGqckPmWK4';
      headers['Content-Type'] = 'application/json';

      print('PDF Viewer: Request headers: $headers');

      final response = await http.get(Uri.parse(url), headers: headers);

      print('PDF Viewer: Download response status: ${response.statusCode}');
      print('PDF Viewer: Content-Type: ${response.headers['content-type']}');
      print('PDF Viewer: Content length: ${response.bodyBytes.length} bytes');

      if (response.statusCode == 200) {
        final contentType =
            response.headers['content-type']?.toLowerCase() ?? '';
        if (contentType.contains('pdf') ||
            contentType.contains('application') ||
            response.bodyBytes.isNotEmpty) {
          print('PDF Viewer: PDF downloaded successfully');
          return response.bodyBytes;
        } else {
          print(
            'PDF Viewer: Downloaded content is not a PDF (content-type: $contentType)',
          );
          print('PDF Viewer: Response body: ${response.body}');
          return null;
        }
      } else {
        print('PDF Viewer: Download failed with status ${response.statusCode}');
        print('PDF Viewer: Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('PDF Viewer: Download failed with error: $e');
      return null;
    }
  }

  Future<bool> _testPdfUrl(String url) async {
    try {
      print('PDF Viewer: Testing URL accessibility: $url');
      final response = await http.head(Uri.parse(url));
      print('PDF Viewer: URL test response status: ${response.statusCode}');
      print('PDF Viewer: Content-Type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        final contentType =
            response.headers['content-type']?.toLowerCase() ?? '';
        if (contentType.contains('pdf') ||
            contentType.contains('application')) {
          print('PDF Viewer: URL is accessible and appears to be a PDF');
          return true;
        } else {
          print(
            'PDF Viewer: URL is accessible but content-type is: $contentType',
          );
          return false;
        }
      } else {
        print('PDF Viewer: URL returned status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('PDF Viewer: URL test failed with error: $e');
      return false;
    }
  }

  void _retryPdfLoad() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _initializeReader();
  }

  Widget _buildEpubViewer() {
    return FutureBuilder<String>(
      future: _downloadAndExtractText(_bookFileUrl!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: skyBlue),
                const SizedBox(height: 16),
                Text(
                  'Loading EPUB content...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
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
                  'Unable to read EPUB file',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[400], fontSize: 12),
                ),
              ],
            ),
          );
        }

        final content = snapshot.data ?? '';
        if (content.isEmpty) {
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
                  'No readable content found in EPUB',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTxtViewer() {
    return FutureBuilder<String>(
      future: _downloadTextFile(_bookFileUrl!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: skyBlue),
                const SizedBox(height: 16),
                Text(
                  'Loading text file...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
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
                  'Unable to read text file',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[400], fontSize: 12),
                ),
              ],
            ),
          );
        }

        final content = snapshot.data ?? '';
        if (content.isEmpty) {
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
                  'File is empty',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        );
      },
    );
  }

  Future<String> _downloadTextFile(String url) async {
    try {
      // Create authenticated request for Supabase storage
      final headers = <String, String>{};
      final supabase = Supabase.instance.client;

      // Add authorization header if user is authenticated
      final session = supabase.auth.currentSession;
      if (session != null && session.accessToken != null) {
        headers['Authorization'] = 'Bearer ${session.accessToken}';
      }

      // Add API key as fallback
      headers['apikey'] =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlyaXl0dXllYW14emN4eXF0YmdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE1NjM3NDgsImV4cCI6MjA2NzEzOTc0OH0.5Coq1Mhj1BMcDLJchHOjk35N8BASkU3NmHGqckPmWK4';
      headers['Content-Type'] = 'application/json';

      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Widget _buildCbzViewer() {
    if (_cbzPages.isEmpty) {
      return FutureBuilder<List<Uint8List>>(
        future: _downloadAndExtractCbz(_bookFileUrl!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: skyBlue),
                  const SizedBox(height: 16),
                  Text(
                    'Loading CBZ comic...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'CBZ Reader',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unable to load CBZ file',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[400], fontSize: 12),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            _cbzPages = snapshot.data!;
            return _buildCbzContent();
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'CBZ Reader',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No images found in CBZ file',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          );
        },
      );
    }

    return _buildCbzContent();
  }

  Widget _buildCbzContent() {
    if (_cbzPages.isEmpty) {
      return const Center(
        child: Text(
          'No pages available',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
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
                          Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load page ${_currentPage + 1}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          _buildCbzBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildCbzBottomNavigationBar() {
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

  void _nextPage() {
    if (_currentPage < _cbzPages.length - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  Future<String> _downloadAndExtractText(String url) async {
    try {
      // Create authenticated request for Supabase storage
      final headers = <String, String>{};
      final supabase = Supabase.instance.client;

      // Add authorization header if user is authenticated
      final session = supabase.auth.currentSession;
      if (session != null && session.accessToken != null) {
        headers['Authorization'] = 'Bearer ${session.accessToken}';
      }

      // Add API key as fallback
      headers['apikey'] =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlyaXl0dXllYW14emN4eXF0YmdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE1NjM3NDgsImV4cCI6MjA2NzEzOTc0OH0.5Coq1Mhj1BMcDLJchHOjk35N8BASkU3NmHGqckPmWK4';
      headers['Content-Type'] = 'application/json';

      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        // Simple text extraction - in reality, EPUB files need proper parsing
        return 'EPUB content extraction not fully implemented yet.\n\nFile: ${widget.book.title}\n\nPlease use a dedicated EPUB reader app for full functionality.';
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Uint8List>> _downloadAndExtractCbz(String url) async {
    try {
      // Create authenticated request for Supabase storage
      final headers = <String, String>{};
      final supabase = Supabase.instance.client;

      // Add authorization header if user is authenticated
      final session = supabase.auth.currentSession;
      if (session != null && session.accessToken != null) {
        headers['Authorization'] = 'Bearer ${session.accessToken}';
      }

      // Add API key as fallback
      headers['apikey'] =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlyaXl0dXllYW14emN4eXF0YmdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE1NjM3NDgsImV4cCI6MjA2NzEzOTc0OH0.5Coq1Mhj1BMcDLJchHOjk35N8BASkU3NmHGqckPmWK4';
      headers['Content-Type'] = 'application/json';

      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
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
        return imageFiles.map((file) => file.content as Uint8List).toList();
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
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
        child: CircularProgressIndicator(color: Color(0xFFFCE4EC)),
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
            child: CircularProgressIndicator(color: Color(0xFFFCE4EC)),
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
