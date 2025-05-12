import '../../domain/entities/follow_entity.dart';

class FollowModel extends FollowEntity {
  const FollowModel({
    required super.id,
    required super.followerId,
    required super.followingId,
    required super.createdAt,
    required super.numberOfPosts,
    required super.numberOfFollowers,
    required super.numberOfFollowing,
  });

  factory FollowModel.fromJson(
    Map<String, dynamic> json, {
    required int numberOfPosts,
    required int numberOfFollowers,
    required int numberOfFollowing,
  }) {
    return FollowModel(
      id: json['id'] as String,
      followerId: json['follower_id'] as String,
      followingId: json['following_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      numberOfPosts: numberOfPosts,
      numberOfFollowers: numberOfFollowers,
      numberOfFollowing: numberOfFollowing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'follower_id': followerId,
      'following_id': followingId,
      'created_at': createdAt.toIso8601String(),
      'number_of_posts': numberOfPosts,
      'number_of_followers': numberOfFollowers,
      'number_of_following': numberOfFollowing,
    };
  }

  factory FollowModel.empty() {
    return FollowModel(
      id: '',
      followerId: '',
      followingId: '',
      createdAt: DateTime.now(),
      numberOfPosts: 0,
      numberOfFollowers: 0,
      numberOfFollowing: 0,
    );
  }

  FollowModel copyWith({
    String? id,
    String? followerId,
    String? followingId,
    DateTime? createdAt,
    int? numberOfPosts,
    int? numberOfFollowers,
    int? numberOfFollowing,
  }) {
    return FollowModel(
      id: id ?? this.id,
      followerId: followerId ?? this.followerId,
      followingId: followingId ?? this.followingId,
      createdAt: createdAt ?? this.createdAt,
      numberOfPosts: numberOfPosts ?? this.numberOfPosts,
      numberOfFollowers: numberOfFollowers ?? this.numberOfFollowers,
      numberOfFollowing: numberOfFollowing ?? this.numberOfFollowing,
    );
  }

  /// Creates a FollowModel from a database row and counts
  static FollowModel fromDatabaseJson(
    Map<String, dynamic> json,
    Map<String, dynamic> counts,
  ) {
    return FollowModel(
      id: json['id'] as String,
      followerId: json['follower_id'] as String,
      followingId: json['following_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      numberOfPosts: counts['posts_count'] as int? ?? 0,
      numberOfFollowers: counts['followers_count'] as int? ?? 0,
      numberOfFollowing: counts['following_count'] as int? ?? 0,
    );
  }

  /// Converts the model to a format suitable for database insertion
  Map<String, dynamic> toDatabaseJson() {
    return {
      'follower_id': followerId,
      'following_id': followingId,
    };
  }
}
