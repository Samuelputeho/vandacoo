import 'package:vandacoo/core/common/entities/comment_entity.dart';

class CommentModel extends CommentEntity {
  CommentModel({
    required super.id,
    required super.posterId,
    required super.userId,
    required super.comment,
    required super.createdAt,
    super.userName,
    super.userProPic,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      posterId: json['posterId'],
      userId: json['userId'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
      userName: json['profiles']?['name'],
      userProPic: json['profiles']?['propic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': posterId,
      'userId': userId,
      'comment': comment,
    };
  }

  CommentModel copyWith({
    String? id,
    String? posterId,
    String? userId,
    String? comment,
    DateTime? createdAt,
    String? userName,
    String? userProPic,
  }) {
    return CommentModel(
      id: id ?? this.id,
      posterId: posterId ?? this.posterId,
      userId: userId ?? this.userId,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userProPic: userProPic ?? this.userProPic,
    );
  }
}