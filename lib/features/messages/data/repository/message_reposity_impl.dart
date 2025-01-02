import 'package:vandacoo/core/error/exceptions.dart';
import 'package:vandacoo/core/error/failure.dart';
import 'package:vandacoo/features/messages/data/datasources/message_remote_data_source.dart';
import 'package:vandacoo/features/messages/domain/entity/message_entity.dart';
import 'package:vandacoo/features/messages/domain/repository/message_repository.dart';
import 'package:fpdart/fpdart.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource remoteDataSource;

  MessageRepositoryImpl({required this.remoteDataSource});
  @override
  Future<Either<Failure, List<MessageEntity>>> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final message = await remoteDataSource.sendMessage(
        senderId: senderId,
        receiverId: receiverId,
        content: content,
      );
      return right([message]); // Wrap message in a list to match return type
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getMessages({
    required String senderId,
    required String receiverId,
  }) async {
    try {
      final messages = await remoteDataSource.getMessages(
        senderId: senderId,
        receiverId: receiverId,
      );
      return Right(messages);
    } on ServerException catch (e) {
      return Left(Failure(e.message));
    }
  }
}
