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
  });
}
