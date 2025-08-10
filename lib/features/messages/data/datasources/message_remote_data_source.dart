import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vandacoo/core/common/models/message_model.dart';
import 'package:vandacoo/core/error/exceptions.dart';
import 'package:vandacoo/core/common/entities/message_entity.dart';

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

  // Add realtime subscription methods
  Stream<MessageModel> subscribeToNewMessages(String userId);
  Stream<List<MessageModel>> subscribeToMessageUpdates(String userId);
  void dispose();
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final SupabaseClient _supabaseClient;
  static const _timeout = Duration(seconds: 10);

  // Add subscription management
  final Map<String, RealtimeChannel> _activeChannels = {};

  MessageRemoteDataSourceImpl(this._supabaseClient);

  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabaseClient
          .from(AppConstants.profilesTable)
          .select()
          .eq('status', 'active');

      final List<UserModel> users = [];

      for (final userData in response) {
        final processedData = {
          'id': userData['id'],
          'name': userData['name'],
          'email': userData['email'],
          'bio': userData['bio'] ?? '',
          'propic': userData['propic'] ?? '',
          'has_seen_intro_video': userData['has_seen_intro_video'] ?? false,
          'account_type': userData['account_type'] ?? 'individual',
          'gender': userData['gender'],
          'age': userData['age'],
          'status': userData['status'] ?? 'active',
        };

        final user = UserModel.fromJson(processedData);
        users.add(user);
      }

      return users;
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
      // First check if the sender is active
      final senderStatus = await _supabaseClient
          .from('profiles')
          .select('status')
          .eq('id', senderId)
          .single();

      if (senderStatus['status'] != 'active') {
        throw ServerException("Only active users can send messages.");
      }

      // Check if the receiver is active
      final receiverStatus = await _supabaseClient
          .from('profiles')
          .select('status')
          .eq('id', receiverId)
          .single();

      if (receiverStatus['status'] != 'active') {
        throw ServerException("Cannot send messages to inactive users.");
      }

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
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<MessageModel>> getMessages({
    required String senderId,
    String? receiverId,
  }) async {
    try {
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
        query = query.or(
            'and(senderId.eq.$senderId,receiverId.eq.$receiverId),and(senderId.eq.$receiverId,receiverId.eq.$senderId)');
      } else {
        query = query.or('senderId.eq.$senderId,receiverId.eq.$senderId');
      }

      // Filter out deleted messages using contains
      query = query.not('deleted_by', 'cs', '{$senderId}');

      final response = await query.order('createdAt', ascending: false);

      return response
          .map((message) =>
              MessageModel.fromJson(Map<String, dynamic>.from(message)))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteMessageThread({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      // First get the messages to update
      final messages = await _supabaseClient
          .from(AppConstants.messagesTable)
          .select('id, deleted_by')
          .or('and(senderId.eq.$userId,receiverId.eq.$otherUserId),and(senderId.eq.$otherUserId,receiverId.eq.$userId)');

      // Update each message's deleted_by array
      for (final message in messages) {
        final List<String> currentDeletedBy =
            ((message['deleted_by'] as List<dynamic>?) ?? [])
                .map((e) => e.toString())
                .toList();

        if (!currentDeletedBy.contains(userId)) {
          // Format the array in PostgreSQL format
          final newDeletedBy = '{${[...currentDeletedBy, userId].join(',')}}';

          await _supabaseClient
              .from(AppConstants.messagesTable)
              .update({'deleted_by': newDeletedBy}).eq('id', message['id']);
        }
      }
    } catch (e) {
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
        final newDeletedBy = '{${[...currentDeletedBy, userId].join(',')}}';

        await _supabaseClient
            .from(AppConstants.messagesTable)
            .update({'deleted_by': newDeletedBy}).eq('id', messageId);
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<MessageModel> subscribeToNewMessages(String userId) {
    final controller = StreamController<MessageModel>.broadcast();
    final channelName = 'messages_$userId';

    // Remove existing channel if any
    if (_activeChannels.containsKey(channelName)) {
      _supabaseClient.removeChannel(_activeChannels[channelName]!);
      _activeChannels.remove(channelName);
    }

    final channel = _supabaseClient
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: AppConstants.messagesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiverId',
            value: userId,
          ),
          callback: (payload) {
            try {
              final message = MessageModel.fromJson(payload.newRecord);
              controller.add(message);
            } catch (e) {
              controller.addError(e);
            }
          },
        )
        .subscribe();

    _activeChannels[channelName] = channel;
    return controller.stream;
  }

  @override
  Stream<List<MessageModel>> subscribeToMessageUpdates(String userId) {
    final controller = StreamController<List<MessageModel>>.broadcast();
    final channelName = 'message_updates_$userId';

    if (_activeChannels.containsKey(channelName)) {
      _supabaseClient.removeChannel(_activeChannels[channelName]!);
      _activeChannels.remove(channelName);
    }

    final channel = _supabaseClient
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: AppConstants.messagesTable,
          callback: (payload) async {
            try {
              // Fetch updated messages for this user
              final messages = await getMessages(senderId: userId);
              controller.add(messages);
            } catch (e) {
              controller.addError(e);
            }
          },
        )
        .subscribe();

    _activeChannels[channelName] = channel;
    return controller.stream;
  }

  @override
  void dispose() {
    for (final channel in _activeChannels.values) {
      _supabaseClient.removeChannel(channel);
    }
    _activeChannels.clear();
  }
}
