class UserModel {
  final String id;
  final String username;
  final String email;
  final String? bio;
  final String? avatarUrl;
  final int booksShared;
  final int favorites;
  final int following;
  final int followers;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.bio,
    this.avatarUrl,
    this.booksShared = 0,
    this.favorites = 0,
    this.following = 0,
    this.followers = 0,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      booksShared: json['books_shared'] ?? 0,
      favorites: json['favorites'] ?? 0,
      following: json['following'] ?? 0,
      followers: json['followers'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'bio': bio,
      'avatar_url': avatarUrl,
      'books_shared': booksShared,
      'favorites': favorites,
      'following': following,
      'followers': followers,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
