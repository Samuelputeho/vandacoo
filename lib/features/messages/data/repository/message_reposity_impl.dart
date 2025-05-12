import 'dart:io';

import 'package:vandacoo/core/error/exceptions.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/features/messages/data/datasources/message_remote_data_source.dart';
import 'package:vandacoo/core/common/entities/message_entity.dart';
import 'package:vandacoo/features/messages/domain/repository/message_repository.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/common/entities/user_entity.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource remoteDataSource;

  MessageRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<UserEntity>>> getAllUsers() async {
    try {
      final users = await remoteDataSource.getAllUsers();
      return right(users);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String senderId,
    String? receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    File? mediaFile,
  }) async {
    try {
      final message = await remoteDataSource.sendMessage(
        senderId: senderId,
        receiverId: receiverId!,
        content: content,
        messageType: messageType,
        mediaFile: mediaFile,
      );
      return right(message);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getMessages({
    required String senderId,
    String? receiverId,
  }) async {
    try {
      final messages = await remoteDataSource.getMessages(
        senderId: senderId,
        receiverId: receiverId,
      );
      return right(messages);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMessageThread({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      await remoteDataSource.deleteMessageThread(
          userId: userId, otherUserId: otherUserId);
      return right(unit);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> markMessageAsRead(
      {required String messageId}) async {
    try {
      await remoteDataSource.markMessageAsRead(messageId: messageId);
      return right(unit);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMessage({
    required String messageId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.deleteMessage(
        messageId: messageId,
        userId: userId,
      );
      return right(unit);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
