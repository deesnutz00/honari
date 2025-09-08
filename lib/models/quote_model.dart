class QuoteModel {
  final String id;
  final String content;
  final String author;
  final DateTime createdAt;
  final bool isActive;

  QuoteModel({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    this.isActive = true,
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      author: json['author'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'author': author,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}
