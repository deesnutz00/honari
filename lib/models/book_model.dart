class BookModel {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String? coverUrl;
  final String? firstPageUrl;
  final String? bookFileUrl;
  final String? bookFilePath;
  final String? genre;
  final String userId;
  final DateTime createdAt;
  final bool isFavorite;
  final int likeCount;
  final bool isLiked;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.coverUrl,
    this.firstPageUrl,
    this.bookFileUrl,
    this.bookFilePath,
    this.genre,
    required this.userId,
    required this.createdAt,
    this.isFavorite = false,
    this.likeCount = 0,
    this.isLiked = false,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      description: json['description'],
      coverUrl: json['cover_url'],
      firstPageUrl: json['first_page_url'],
      bookFileUrl: json['book_file_url'],
      bookFilePath: json['book_file_path'],
      genre: json['genre'],
      userId: json['user_id'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      isFavorite: json['is_favorite'] ?? false,
      likeCount: json['like_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'cover_url': coverUrl,
      'first_page_url': firstPageUrl,
      'book_file_url': bookFileUrl,
      'book_file_path': bookFilePath,
      'genre': genre,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'is_favorite': isFavorite,
      'like_count': likeCount,
      'is_liked': isLiked,
    };
  }
}
