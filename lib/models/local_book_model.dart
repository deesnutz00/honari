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
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks} week${weeks == 1 ? '' : 's'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months} month${months == 1 ? '' : 's'} ago';
    }
  }

  bool get isComicBook => fileExtension.toLowerCase() == 'cbz';

  factory LocalBookModel.fromJson(Map<String, dynamic> json) {
    return LocalBookModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      genre: json['genre'],
      filePath: json['filePath'] ?? '',
      fileName: json['fileName'] ?? '',
      fileExtension: json['fileExtension'] ?? '',
      fileSizeBytes: json['fileSizeBytes'] ?? 0,
      lastOpened: DateTime.parse(json['lastOpened'] ?? DateTime.now().toIso8601String()),
      addedDate: DateTime.parse(json['addedDate'] ?? DateTime.now().toIso8601String()),
      coverPath: json['coverPath'],
      totalPages: json['totalPages'],
      readingProgress: json['readingProgress']?.toDouble(),
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
