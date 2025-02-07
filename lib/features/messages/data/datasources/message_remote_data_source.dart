import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vandacoo/features/messages/data/models/message_model.dart';
import 'package:vandacoo/core/error/exceptions.dart';
import 'package:vandacoo/features/messages/domain/entity/message_entity.dart';

import '../../../../core/common/models/user_model.dart';
import '../../../../core/constants/app_consts.dart';

abstract class MessageRemoteDataSource {
  Future<MessageModel> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    File? mediaFile,
  });

  Future<List<MessageModel>> getMessages({
    required String senderId,
    String? receiverId,
  });

  Future<void> deleteMessageThread({
    required String userId,
    required String otherUserId,
  });

  Future<void> markMessageAsRead({
    required String messageId,
  });

  Future<void> deleteMessage({
    required String messageId,
    required String userId,
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
      final response = await _supabaseClient
          .from(AppConstants.profilesTable)
          .select()
          .timeout(
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
    MessageType messageType = MessageType.text,
    File? mediaFile,
  }) async {
    try {
      String? mediaUrl;
      if (mediaFile != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${mediaFile.path.split('/').last}';

        // Upload the file to storage
        await _supabaseClient.storage
            .from(AppConstants.messageMediaTable)
            .upload(fileName, mediaFile);

        // Get the public URL
        mediaUrl = _supabaseClient.storage
            .from(AppConstants.messageMediaTable)
            .getPublicUrl(fileName);

        print('Media uploaded successfully. URL: $mediaUrl');
      }

      final response = await _supabaseClient
          .from(AppConstants.messagesTable)
          .insert({
            'senderId': senderId,
            'receiverId': receiverId,
            'content': content,
            'createdAt': DateTime.now().toIso8601String(),
            'messageType': messageType.toString().split('.').last,
            'mediaUrl': mediaUrl,
            'deleted_by': '{}', // Initialize empty array
          })
          .select()
          .single();

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
    try {
      print('Fetching messages for user $senderId');

      // Build the base query with explicit column selection
      var baseQuery = '''
        id,
        senderId,
        receiverId,
        content,
        createdAt,
        read_at,
        mediaUrl,
        messageType,
        deleted_by
      ''';

      // Start with the base query
      var query =
          _supabaseClient.from(AppConstants.messagesTable).select(baseQuery);

      // Add the conversation filter first
      if (receiverId != null && receiverId.isNotEmpty) {
        print('Fetching conversation with user $receiverId');
        query = query.or(
            'and(senderId.eq.$senderId,receiverId.eq.$receiverId),and(senderId.eq.$receiverId,receiverId.eq.$senderId)');
      } else {
        print('Fetching all conversations');
        query = query.or('senderId.eq.$senderId,receiverId.eq.$senderId');
      }

      // Filter out deleted messages using contains
      query = query.not('deleted_by', 'cs', '{$senderId}');

      final response = await query.order('createdAt', ascending: false);
      print('Found ${(response as List).length} messages');
      print('Response data: $response'); // Debug print to see the actual data

      return response
          .map((message) =>
              MessageModel.fromJson(Map<String, dynamic>.from(message)))
          .toList();
    } catch (e) {
      print('Error fetching messages: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteMessageThread({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      print('Attempting to soft delete message thread for user $userId');

      // First get the messages to update
      final messages = await _supabaseClient
          .from(AppConstants.messagesTable)
          .select('id, deleted_by')
          .or('and(senderId.eq.$userId,receiverId.eq.$otherUserId),and(senderId.eq.$otherUserId,receiverId.eq.$userId)');

      print('Found ${messages.length} messages to update');

      // Update each message's deleted_by array
      for (final message in messages) {
        final List<String> currentDeletedBy =
            ((message['deleted_by'] as List<dynamic>?) ?? [])
                .map((e) => e.toString())
                .toList();

        if (!currentDeletedBy.contains(userId)) {
          print(
              'Current deleted_by for message ${message['id']}: $currentDeletedBy');

          // Format the array in PostgreSQL format
          final newDeletedBy = '{${[...currentDeletedBy, userId].join(',')}}';
          print('New deleted_by array: $newDeletedBy');

          await _supabaseClient
              .from(AppConstants.messagesTable)
              .update({'deleted_by': newDeletedBy}).eq('id', message['id']);

          print(
              'Updated message ${message['id']} with deleted_by: $newDeletedBy');
        } else {
          print('Message ${message['id']} already deleted by user $userId');
        }
      }

      print('Message thread soft deletion successful');
    } catch (e) {
      print('Error soft deleting message thread: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> markMessageAsRead({
    required String messageId,
  }) async {
    try {
      await _supabaseClient.from(AppConstants.messagesTable).update(
          {'read_at': DateTime.now().toIso8601String()}).eq('id', messageId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteMessage({
    required String messageId,
    required String userId,
  }) async {
    try {
      print('Attempting to soft delete message $messageId for user $userId');

      final message = await _supabaseClient
          .from(AppConstants.messagesTable)
          .select('deleted_by')
          .eq('id', messageId)
          .single();

      final List<String> currentDeletedBy =
          ((message['deleted_by'] as List<dynamic>?) ?? [])
              .map((e) => e.toString())
              .toList();

      if (!currentDeletedBy.contains(userId)) {
        print('Current deleted_by for message: $currentDeletedBy');

        final newDeletedBy = '{${[...currentDeletedBy, userId].join(',')}}';
        print('New deleted_by array: $newDeletedBy');

        await _supabaseClient
            .from(AppConstants.messagesTable)
            .update({'deleted_by': newDeletedBy}).eq('id', messageId);

        print('Message soft deletion successful');
      } else {
        print('Message already deleted by user $userId');
      }
    } catch (e) {
      print('Error soft deleting message: $e');
      throw ServerException(e.toString());
    }
  }
}
