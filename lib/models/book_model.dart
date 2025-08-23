class BookModel {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String? coverUrl;
  final String? genre;
  final String userId;
  final DateTime createdAt;
  final bool isFavorite;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.coverUrl,
    this.genre,
    required this.userId,
    required this.createdAt,
    this.isFavorite = false,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      description: json['description'],
      coverUrl: json['cover_url'],
      genre: json['genre'],
      userId: json['user_id'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'cover_url': coverUrl,
      'genre': genre,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'is_favorite': isFavorite,
    };
  }
}
