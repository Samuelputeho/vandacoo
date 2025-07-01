import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/core/common/entities/message_entity.dart';

import '../../../../core/common/entities/user_entity.dart';

abstract class MessageRepository {
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    File? mediaFile,
  });

  Future<Either<Failure, List<MessageEntity>>> getMessages({
    required String senderId,
    String? receiverId,
  });

  Future<Either<Failure, Unit>> deleteMessageThread({
    required String userId,
    required String otherUserId,
  });

  Future<Either<Failure, Unit>> markMessageAsRead({
    required String messageId,
  });

  Future<Either<Failure, Unit>> deleteMessage({
    required String messageId,
    required String userId,
  });

  Future<Either<Failure, List<UserEntity>>> getAllUsers();

  // Realtime subscription methods
  Stream<Either<Failure, MessageEntity>> subscribeToNewMessages(String userId);
  Stream<Either<Failure, List<MessageEntity>>> subscribeToMessageUpdates(
      String userId);
  void dispose();
}
