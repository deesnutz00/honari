import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/book_service.dart';
import 'dart:io';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? fileName;
  FilePickerResult? pickedFile;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController genreController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final Color skyBlue = const Color(0xFF87CEEB);
  final Color lightSkyBlue = const Color(0xFFE0F0FF);
  final BookService _bookService = BookService();
  bool _isUploading = false;
  final InputBorder inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  );

  Future<void> pickBook() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub', 'cbz', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          pickedFile = result;
          fileName = result.files.first.name;
        });
      }
    } catch (e) {
      // Handle any errors that might occur during file picking
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    genreController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Share a Book',
          style: TextStyle(
            color: Color(0xFF87CEEB),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add your favorite books to the community\nSupported formats: PDF, EPUB, CBZ, TXT',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: pickBook,
              child: DottedBorder(
                borderType: BorderType.RRect,
                radius: const Radius.circular(12),
                color: const Color(0xFF87CEEB),
                strokeWidth: 1.5,
                dashPattern: const [8, 4],
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF5F5F5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          fileName != null
                              ? Icons.file_present
                              : Icons.file_upload_outlined,
                          size: 32,
                          color: fileName != null ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          fileName ?? 'Tap to select book file',
                          style: TextStyle(
                            color: fileName != null
                                ? Colors.black
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (fileName != null) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Book file selected',
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Book Information',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF87CEEB),
              ),
            ),
            const SizedBox(height: 16),
            buildInputField(
              titleController,
              'Book title *',
              Icons.menu_book_outlined,
            ),
            const SizedBox(height: 12),
            buildInputField(
              authorController,
              'Author name *',
              Icons.person_outline,
            ),
            const SizedBox(height: 12),
            buildInputField(
              genreController,
              'Genre (e.g., Fiction, Philosophy)',
              Icons.local_offer_outlined,
            ),
            const SizedBox(height: 12),
            buildInputField(
              descriptionController,
              'Description (optional)',
              Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (pickedFile != null && !_isUploading)
                  ? () async {
                      if (titleController.text.isEmpty ||
                          authorController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter book title and author name',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _isUploading = true;
                      });

                      try {
                        print('🚀 Starting book upload process...');

                        // Get current user
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user == null) {
                          throw Exception('User not authenticated');
                        }

                        print('👤 User authenticated: ${user.id}');

                        // Upload file to Supabase storage
                        final path = pickedFile!.files.first.path;
                        if (path == null) {
                          throw Exception('Could not read file path');
                        }

                        final file = File(path);
                        final fileExt =
                            pickedFile!.files.first.extension ?? 'pdf';
                        final uniqueFileName =
                            '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

                        print('📁 Uploading file: $uniqueFileName');

                        await Supabase.instance.client.storage
                            .from('deesnutz00')
                            .upload(uniqueFileName, file);

                        print('✅ File uploaded to storage successfully');

                        // Get public URL for the uploaded file from the same bucket
                        final fileUrl = Supabase.instance.client.storage
                            .from('deesnutz00')
                            .getPublicUrl(uniqueFileName);

                        print('🔗 File URL: $fileUrl');

                        // Create book record in database
                        print('📚 Creating book record in database...');
                        final bookId = await _bookService.createBook(
                          title: titleController.text,
                          author: authorController.text,
                          description: descriptionController.text,
                          genre: genreController.text,
                          coverUrl: fileUrl,
                          userId: user.id,
                        );

                        print('✅ Book record created with ID: $bookId');

                        // Show success message
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Book uploaded successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // Clear form
                        titleController.clear();
                        authorController.clear();
                        genreController.clear();
                        descriptionController.clear();
                        setState(() {
                          pickedFile = null;
                          fileName = null; // properly clear filename
                        });
                      } catch (e) {
                        print('❌ Upload error: $e');
                        print('❌ Error type: ${e.runtimeType}');
                        print('❌ Error details: ${e.toString()}');

                        if (!mounted) return;

                        String errorMessage = 'Error uploading book';
                        if (e.toString().contains('403')) {
                          errorMessage =
                              'Permission denied (403). Check database permissions and RLS policies.';
                        } else if (e.toString().contains('relation') &&
                            e.toString().contains('does not exist')) {
                          errorMessage =
                              'Database table missing. Create the "books" table in Supabase.';
                        } else if (e.toString().contains('permission denied')) {
                          errorMessage =
                              'Permission denied. Check Row Level Security policies.';
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isUploading = false;
                          });
                        }
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (pickedFile != null && !_isUploading)
                    ? skyBlue
                    : Colors.grey,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isUploading ? 'Uploading...' : 'Upload Book',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInputField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder,
      ),
    );
  }
}
