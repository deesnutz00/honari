class LocalBookModel {
  final String id;
  final String title;
  final String author;
  final String? genre;
  final String filePath;
  final String fileName;
  final String fileExtension;
  final int fileSizeBytes;
  final DateTime lastOpened;
  final DateTime addedDate;
  final String? coverPath;
  final int? totalPages;
  final double? readingProgress;

  LocalBookModel({
    required this.id,
    required this.title,
    required this.author,
    this.genre,
    required this.filePath,
    required this.fileName,
    required this.fileExtension,
    required this.fileSizeBytes,
    required this.lastOpened,
    required this.addedDate,
    this.coverPath,
    this.totalPages,
    this.readingProgress,
  });

  String get fileSize {
    if (fileSizeBytes < 1024) {
      return '${fileSizeBytes} B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get lastOpenedText {
    final now = DateTime.now();
    final difference = now.difference(lastOpened);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${lastOpened.day}/${lastOpened.month}/${lastOpened.year}';
    }
  }
  
  // Add lastReadPage getter to convert readingProgress to page number
  int? get lastReadPage {
    if (readingProgress == null || totalPages == null) return null;
    return (readingProgress! * totalPages!).round();
  }

  bool get isComicBook => fileExtension.toLowerCase() == 'cbz';

  factory LocalBookModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) {
        return DateTime.now();
      }
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        print('Error parsing date: $e');
        return DateTime.now();
      }
    }

    return LocalBookModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      genre: json['genre'],
      filePath: json['filePath'] ?? '',
      fileName: json['fileName'] ?? '',
      fileExtension: json['fileExtension'] ?? '',
      fileSizeBytes: json['fileSizeBytes'] is int 
          ? json['fileSizeBytes'] 
          : int.tryParse(json['fileSizeBytes']?.toString() ?? '0') ?? 0,
      lastOpened: parseDateTime(json['lastOpened']),
      addedDate: parseDateTime(json['addedDate']),
      coverPath: json['coverPath'],
      totalPages: json['totalPages'] is int 
          ? json['totalPages'] 
          : int.tryParse(json['totalPages']?.toString() ?? '0'),
      readingProgress: json['readingProgress'] is double 
          ? json['readingProgress'] 
          : double.tryParse(json['readingProgress']?.toString() ?? '0.0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'genre': genre,
      'filePath': filePath,
      'fileName': fileName,
      'fileExtension': fileExtension,
      'fileSizeBytes': fileSizeBytes,
      'lastOpened': lastOpened.toIso8601String(),
      'addedDate': addedDate.toIso8601String(),
      'coverPath': coverPath,
      'totalPages': totalPages,
      'readingProgress': readingProgress,
    };
  }

  LocalBookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? genre,
    String? filePath,
    String? fileName,
    String? fileExtension,
    int? fileSizeBytes,
    DateTime? lastOpened,
    DateTime? addedDate,
    String? coverPath,
    int? totalPages,
    double? readingProgress,
  }) {
    return LocalBookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileExtension: fileExtension ?? this.fileExtension,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      lastOpened: lastOpened ?? this.lastOpened,
      addedDate: addedDate ?? this.addedDate,
      coverPath: coverPath ?? this.coverPath,
      totalPages: totalPages ?? this.totalPages,
      readingProgress: readingProgress ?? this.readingProgress,
    );
  }
}
