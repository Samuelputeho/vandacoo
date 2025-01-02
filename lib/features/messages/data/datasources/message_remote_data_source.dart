import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vandacoo/features/messages/data/models/message_model.dart';
import 'package:vandacoo/core/error/exceptions.dart';

import '../../../../core/common/models/user_model.dart';

abstract class MessageRemoteDataSource {
  Future<MessageModel> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  });

  Future<List<MessageModel>> getMessages({
    required String senderId,
    String? receiverId,
  });
  Future<List<UserModel>> getAllUsers();
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final SupabaseClient _supabaseClient;
  static const _timeout = Duration(seconds: 10);

  const MessageRemoteDataSourceImpl(this._supabaseClient);
  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabaseClient.from('profiles').select().timeout(
            _timeout,
            onTimeout: () => throw ServerException(
                'Connection timeout. Please check your internet connection.'),
          );

      return (response as List)
          .map((user) => UserModel.fromJson(user))
          .toList();
    } on TimeoutException {
      throw ServerException(
          'Connection timeout. Please check your internet connection.');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    print('Attempting to send message:');
    print('Sender ID: $senderId');
    print('Receiver ID: $receiverId');
    print('Content: $content');

    if (senderId.isEmpty || receiverId.isEmpty) {
      throw ArgumentError('Sender ID and Receiver ID must not be empty.');
    }

    try {
      final response = await _supabaseClient
          .from('messages')
          .insert({
            'senderId': senderId,
            'receiverId': receiverId,
            'content': content,
            'createdAt': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      print('Message sent successfully. Response: $response');
      return MessageModel.fromJson(response);
    } catch (e) {
      print('Error sending message: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<MessageModel>> getMessages({
    required String senderId,
    String? receiverId,
  }) async {
    print('Attempting to get messages:');
    print('Sender ID: $senderId');
    print('Receiver ID: $receiverId');

    try {
      final query = _supabaseClient.from('messages').select();

      if (receiverId != null && receiverId.isNotEmpty) {
        query.or(
            'and(senderId.eq.$senderId,receiverId.eq.$receiverId),and(senderId.eq.$receiverId,receiverId.eq.$senderId)');
      } else {
        query.or('senderId.eq.$senderId,receiverId.eq.$senderId');
      }

      final response =
          await query.order('createdAt', ascending: false).timeout(_timeout);

      print('Got messages response: $response');

      final messages = (response as List)
          .map((message) =>
              MessageModel.fromJson(Map<String, dynamic>.from(message)))
          .toList();

      print('Parsed ${messages.length} messages');
      return messages;
    } catch (e) {
      print('Error getting messages: $e');
      throw ServerException(e.toString());
    }
  }
}
