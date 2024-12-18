// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class PostEntity {
  final String id;
  final String posterId;
  final String category;
  final String caption;
  final String image;
  final String region;
  final DateTime updatedAt;
  final String? posterName;
  final String? posterProPic;

  PostEntity({
    required this.id,
    required this.posterId,
    required this.category,
    required this.caption,
    required this.image,
    required this.region,
    required this.updatedAt,
     this.posterName,
     this.posterProPic,
  });
}
