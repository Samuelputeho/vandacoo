import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/features/messages/domain/entity/message_entity.dart';

import '../../../../core/common/entities/user_entity.dart';

abstract class MessageRepository {
  Future<Either<Failure, List<MessageEntity>>> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  });

  Future<Either<Failure, List<MessageEntity>>> getMessages({
    required String senderId,
    required String receiverId,
  });

  Future<Either<Failure, List<UserEntity>>> getAllUsers();
}
