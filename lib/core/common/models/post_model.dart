import 'package:vandacoo/core/common/entities/post_entity.dart';

class PostModel extends PostEntity {
  PostModel({
    required super.id,
    required super.region,
    required super.posterId,
    required super.category,
    required super.caption,
    required super.image,
    required super.updatedAt,
    super.posterName,
    super.posterProPic,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'posterId': posterId,
      'category': category,
      'caption': caption,
      'image': image,
      'region': region,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PostModel.fromJson(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] as String,
      region: map['region'] as String,
      posterId: map['posterId'] as String,
      category: map['category'] as String,
      caption: map['caption'] as String,
      image: map['image'] as String,
      updatedAt: map['updatedAt'] == null
          ? DateTime.now()
          : DateTime.parse(map['updatedAt']),
      posterName: map['profiles']?['name'],
      posterProPic: map['profiles']?['propic'],
    );
  }

  PostModel copyWith({
    String? id,
    String? posterId,
    String? category,
    String? caption,
    String? image,
    DateTime? updatedAt,
    String? posterName,
    String? posterProPic,
  }) {
    return PostModel(
      id: id ?? this.id,
      region: region ?? region,
      posterId: posterId ?? this.posterId,
      category: category ?? this.category,
      caption: caption ?? this.caption,
      image: image ?? this.image,
      updatedAt: updatedAt ?? this.updatedAt,
      posterName: posterName ?? this.posterName,
      posterProPic: posterProPic ?? this.posterProPic,
    );
  }
}
