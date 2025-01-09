import '../entities/story_entitiy.dart';

class StoryModel extends StoryEntity {
  StoryModel({
    required super.id,
    required super.userId,
    required super.postId,
    required super.createdAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'],
      userId: json['userId'],
      postId: json['postId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
