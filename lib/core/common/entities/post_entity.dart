// ignore_for_file: public_member_api_docs, sort_constructors_first

class PostEntity {
  final String id;
  final String userId;
  final String category;
  final String? caption;
  final String? imageUrl;
  final String region;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String status;
  final String postType;
  final String? videoUrl;
  final String? posterName;
  final String? posterProPic;
  final bool isBookmarked;

  PostEntity({
    required this.id,
    required this.userId,
    required this.category,
    this.caption,
    this.imageUrl,
    required this.region,
    required this.updatedAt,
    required this.createdAt,
    required this.status,
    required this.postType,
    this.videoUrl,
    this.posterName,
    this.posterProPic,
    this.isBookmarked = false,
  });

  PostEntity copyWith({
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
  }) {
    return PostEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      caption: caption ?? this.caption,
      imageUrl: imageUrl ?? this.imageUrl,
      region: region ?? this.region,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      postType: postType ?? this.postType,
      videoUrl: videoUrl ?? this.videoUrl,
      posterName: posterName ?? this.posterName,
      posterProPic: posterProPic ?? this.posterProPic,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
