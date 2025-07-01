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
      print('Fetching all users...');
      // First get all users with their basic information
      final response =
          await _supabaseClient.from(AppConstants.profilesTable).select('''
            *,
            followers:${AppConstants.followsTable}!follows_following_id_fkey(
              follower:profiles!follows_follower_id_fkey(*)
            ),
            following:${AppConstants.followsTable}!follows_follower_id_fkey(
              following:profiles!follows_following_id_fkey(*)
            )
          ''').eq('status', 'active').timeout(
                _timeout,
                onTimeout: () => throw ServerException(
                    'Connection timeout. Please check your internet connection.'),
              );

      print('Raw users response: $response');

      final users = (response as List).map((userData) {
        // Extract followers and following from the nested data
        final List<dynamic> followersData = (userData['followers'] ?? [])
            .map((f) => f['follower'])
            .where((f) => f != null)
            .toList();
        final List<dynamic> followingData = (userData['following'] ?? [])
            .map((f) => f['following'])
            .where((f) => f != null)
            .toList();

        // Create a new map with the processed data and explicitly cast it
        final processedData = <String, dynamic>{
          ...Map<String, dynamic>.from(userData),
          'followers': followersData,
          'following': followingData,
        };

        print('Processing user: ${userData['id']} - ${userData['name']}');
        print('User data: $processedData');

        final user = UserModel.fromJson(processedData);
        print('Created user model: ${user.id} - ${user.name}');
        return user;
      }).toList();

      print('Processed ${users.length} users');
      print('Users: ${users.map((u) => '${u.id}: ${u.name}').join(', ')}');
      return users;
    } on TimeoutException {
      throw ServerException(
          'Connection timeout. Please check your internet connection.');
    } catch (e) {
      print('Error fetching users: $e');
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
