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
    };
  }

  factory PostModel.fromJson(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] as String,
      region: map['region'] as String,
      userId: map['user_id'] as String,
      category: map['category'] as String,
      caption: map['caption'] as String?,
      imageUrl: map['image_url'] as String?,
      updatedAt: map['updated_at'] == null
          ? DateTime.now()
          : DateTime.parse(map['updated_at']),
      createdAt: map['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(map['created_at']),
      status: map['status'] as String? ?? 'active',
      postType: map['post_type'] as String? ?? 'Post',
      videoUrl: map['video_url'] as String?,
      posterName: map['profiles']?['name'],
      posterProPic: map['profiles']?['propic'],
    );
  }

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
    );
  }
}
