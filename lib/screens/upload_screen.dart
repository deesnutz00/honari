import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

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
  final Color sakuraPink = const Color(0xFFFCE4EC);
  final InputBorder inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  );

  Future<void> pickPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Share a Book',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
              'Add your favorite books to the community',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: pickPDF,
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
                          fileName ?? 'Tap to select PDF file',
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
                          Text(
                            'PDF file selected',
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
                color: Colors.black,
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
              onPressed: pickedFile != null
                  ? () {
                      // Handle upload logic
                      if (titleController.text.isNotEmpty &&
                          authorController.text.isNotEmpty) {
                        // TODO: Implement actual upload logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Upload functionality coming soon!'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all required fields'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: pickedFile != null ? skyBlue : Colors.grey,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Upload Book",
                style: TextStyle(
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
