class LikeModel {
  final String id;
  final String bookId;
  final String userId;
  final DateTime createdAt;

  LikeModel({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.createdAt,
  });

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    return LikeModel(
      id: json['id'] ?? '',
      bookId: json['book_id'] ?? '',
      userId: json['user_id'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
