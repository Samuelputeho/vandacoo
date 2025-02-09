import 'package:vandacoo/core/common/entities/post_entity.dart';

class PostModel extends PostEntity {
  PostModel({
    required super.id,
    required super.region,
    required super.userId,
    required super.category,
    super.caption,
    super.imageUrl,
    required super.updatedAt,
    required super.createdAt,
    required super.status,
    required super.postType,
    super.videoUrl,
    super.posterName,
    super.posterProPic,
    required super.isBookmarked,
    required super.isLiked,
    required super.likesCount,
    required super.isPostLikedByUser,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'category': category,
      'caption': caption,
      'image_url': imageUrl,
      'region': region,
      'updated_at': updatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'post_type': postType,
      'video_url': videoUrl,
      'is_liked': isLiked,
      'likes_count': likesCount,
      'is_post_liked_by_user': isPostLikedByUser,
    };
  }

  factory PostModel.fromJson(Map<String, dynamic> map) {
    String? cleanUrl(String? url) {
      if (url == null || url.isEmpty) return url;
      return url.trim().replaceAll(RegExp(r'\s+'), '');
    }

    int getLikesCount(dynamic likesCount) {
      if (likesCount is List) {
        return likesCount.isNotEmpty
            ? (likesCount[0]['count'] as int?) ?? 0
            : 0;
      }
      return (likesCount as int?) ?? 0;
    }

    return PostModel(
      id: map['id'] as String,
      region: map['region'] as String,
      userId: map['user_id'] as String,
      category: map['category'] as String,
      caption: map['caption'] as String?,
      imageUrl: cleanUrl(map['image_url'] as String?),
      updatedAt: map['updated_at'] == null
          ? DateTime.now()
          : DateTime.parse(map['updated_at']),
      createdAt: map['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(map['created_at']),
      status: map['status'] as String? ?? 'active',
      postType: map['post_type'] as String? ?? 'Post',
      videoUrl: cleanUrl(map['video_url'] as String?),
      posterName: map['profiles']?['name'],
      posterProPic: cleanUrl(map['profiles']?['propic']),
      isBookmarked: map['is_bookmarked'] as bool? ?? false,
      isLiked: map['is_liked'] as bool? ?? false,
      likesCount: getLikesCount(map['likes_count']),
      isPostLikedByUser: map['is_post_liked_by_user'] as bool? ?? false,
    );
  }

  @override
  PostModel copyWith({
    String? id,
    String? userId,
    String? category,
    String? caption,
    String? imageUrl,
    String? region,
    DateTime? updatedAt,
    DateTime? createdAt,
    String? status,
    String? postType,
    String? videoUrl,
    String? posterName,
    String? posterProPic,
    bool? isBookmarked,
    bool? isLiked,
    int? likesCount,
    bool? isPostLikedByUser,
  }) {
    return PostModel(
      id: id ?? this.id,
      region: region ?? this.region,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      postType: postType ?? this.postType,
      videoUrl: videoUrl ?? this.videoUrl,
      posterName: posterName ?? this.posterName,
      posterProPic: posterProPic ?? this.posterProPic,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isLiked: isLiked ?? this.isLiked,
      likesCount: likesCount ?? this.likesCount,
      isPostLikedByUser: isPostLikedByUser ?? this.isPostLikedByUser,
    );
  }
}
