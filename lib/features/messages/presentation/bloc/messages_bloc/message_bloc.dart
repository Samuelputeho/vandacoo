import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// ignore: depend_on_referenced_packages
import 'package:meta/meta.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/core/common/models/user_model.dart';
import 'package:vandacoo/core/usecase/usecase.dart';
import 'package:vandacoo/features/messages/domain/usecase/delete_message_thread_usecase.dart';
import 'package:vandacoo/features/messages/domain/usecase/delete_message_usecase.dart';
import 'package:vandacoo/features/messages/domain/usecase/get_all_users_for_message.dart';
import 'package:vandacoo/features/messages/domain/usecase/get_mesaages_usecase.dart';
import 'package:vandacoo/features/messages/domain/usecase/mark_message_read_usecase.dart';
import 'package:vandacoo/features/messages/domain/usecase/send_message_usecase.dart';
import 'package:vandacoo/core/common/entities/message_entity.dart';
import 'package:vandacoo/core/error/failure.dart';

part 'message_event.dart';
part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final SendMessageUsecase sendMessageUsecase;
  final GetMessagesUsecase getMessagesUsecase;
  final DeleteMessageThreadUsecase deleteMessageThreadUsecase;
  final MarkMessageReadUsecase markMessageReadUsecase;
  final GetAllUsersForMessageUseCase getAllUsersUsecase;
  final DeleteMessageUsecase deleteMessageUsecase;
  final Set<String> _readMessages = {};
  MessageEntity? lastNotifiedMessage; // Keep track of last notified message
  MessageLoaded?
      _lastLoadedState; // Keep track of last loaded state with user data
  final Set<String> _notifiedMessageIds = {}; // Track notified message IDs

  bool _isMessageRead(MessageEntity message) {
    return message.readAt != null || _readMessages.contains(message.id);
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  MessageBloc({
    required this.sendMessageUsecase,
    required this.getMessagesUsecase,
    required this.deleteMessageThreadUsecase,
    required this.markMessageReadUsecase,
    required this.getAllUsersUsecase,
    required this.deleteMessageUsecase,
  }) : super(MessageInitial()) {
    _initializeNotifications();
    on<SendMessageEvent>(_onSendMessage);
    on<FetchMessagesEvent>(_onFetchMessages);
    on<FetchAllMessagesEvent>(_onFetchAllMessages);
    on<DeleteMessageThreadEvent>(_onDeleteMessageThread);
    on<MarkMessageAsReadEvent>(_onMarkMessageAsRead);
    on<FetchAllUsersEvent>(_onFetchAllUsers);
    on<DeleteMessageEvent>(_onDeleteMessage);
  }

  @override
  void onChange(Change<MessageState> change) {
    super.onChange(change);
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(MessageLoading());
    final result = await sendMessageUsecase(SendMessageParams(
      senderId: event.senderId,
      receiverId: event.receiverId,
      content: event.content,
      messageType: event.messageType,
      mediaFile: event.mediaFile,
    ));

    result.fold(
      (failure) => emit(MessageFailure(_mapFailureToMessage(failure))),
      (message) {
        if (state is MessageLoaded) {
          final currentState = state as MessageLoaded;
          emit(MessageLoaded(
            messages: [...currentState.messages, message],
            users: currentState.users,
            currentUser: currentState.currentUser,
          ));
        } else {
          emit(MessageSent(message));
        }
      },
    );
  }

  Future<void> _onFetchMessages(
    FetchMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    try {
      print(
          'Starting to fetch messages for conversation: ${event.senderId} -> ${event.receiverId}');
      emit(MessageLoading());

      final result = await getMessagesUsecase(GetMessagesParams(
        senderId: event.senderId,
        receiverId: event.receiverId,
      ));

      await result.fold(
        (failure) async {
          print('Failed to fetch messages: ${failure.message}');
          emit(MessageFailure(_mapFailureToMessage(failure)));
        },
        (messages) async {
          print('Successfully fetched ${messages.length} messages');

          List<UserEntity> users = [];
          UserEntity currentUser = UserModel(
            id: event.senderId,
            name: '',
            email: '',
            bio: '',
            propic: '',
            accountType: '',
            gender: '',
            age: '',
            hasSeenIntroVideo: false,
          );

          if (state is MessageLoaded) {
            final currentState = state as MessageLoaded;
            users = currentState.users;
            currentUser = currentState.currentUser;
          } else if (state is UsersLoaded) {
            users = (state as UsersLoaded).users;
          }

          // Filter messages to ensure they're only between the sender and receiver
          final filteredMessages = messages.where((message) {
            // For a specific conversation, only show messages between these two users
            if (event.receiverId != null && event.receiverId!.isNotEmpty) {
              return (message.senderId == event.senderId &&
                      message.receiverId == event.receiverId) ||
                  (message.senderId == event.receiverId &&
                      message.receiverId == event.senderId);
            }
            // For all conversations, show messages where the user is either sender or receiver
            return message.senderId == event.senderId ||
                message.receiverId == event.senderId;
          }).toList();

          print(
              'Filtered to ${filteredMessages.length} messages for the conversation');
          emit(MessageLoaded(
              messages: filteredMessages,
              users: users,
              currentUser: currentUser));
        },
      );
    } catch (e, stackTrace) {
      print('❌ Error in _onFetchMessages: $e');
      print('Stack trace: $stackTrace');
      emit(MessageFailure(e.toString()));
    }
  }

  Future<void> _onFetchAllMessages(
    FetchAllMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    try {
      print('Starting to fetch all messages for user: ${event.userId}');

      // Always fetch users first to ensure we have the latest user data
      print('Fetching users first...');
      emit(MessageLoading());

      final usersResult = await getAllUsersUsecase(NoParams());
      List<UserEntity> users = [];

      await usersResult.fold(
        (failure) async {
          print('Failed to fetch users: ${failure.message}');
          emit(MessageFailure(_mapFailureToMessage(failure)));
          return;
        },
        (fetchedUsers) async {
          print('Successfully fetched ${fetchedUsers.length} users');
          print(
              'Users data: ${fetchedUsers.map((u) => '${u.id}: ${u.name}').join(', ')}');
          users = fetchedUsers;
        },
      );

      // Fetch messages
      print('Fetching messages...');

      final messagesResult =
          await getMessagesUsecase(GetMessagesParams(senderId: event.userId));

      await messagesResult.fold(
        (failure) async {
          print('Failed to fetch messages: ${failure.message}');
          emit(MessageFailure(_mapFailureToMessage(failure)));
        },
        (messages) async {
          print('Successfully fetched ${messages.length} messages');

          // Get current user from the fetched users
          UserEntity currentUser = users.firstWhere(
            (user) => user.id == event.userId,
            orElse: () => UserModel(
              id: event.userId,
              name: 'Unknown User',
              email: '',
              bio: '',
              propic: '',
              accountType: '',
              gender: '',
              age: '',
              hasSeenIntroVideo: false,
            ),
          );

          // Filter messages to ensure they're only between the sender and receiver
          final filteredMessages = messages.where((message) {
            // For all conversations, show messages where the user is either sender or receiver
            return message.senderId == event.userId ||
                message.receiverId == event.userId;
          }).toList();

          print(
              'Filtered to ${filteredMessages.length} messages for all conversations');

          // Create and store the loaded state
          final loadedState = MessageLoaded(
            messages: filteredMessages,
            users: users,
            currentUser: currentUser,
          );
          _lastLoadedState = loadedState; // Store the state for notifications

          print(
              'Emitting MessageLoaded state with ${filteredMessages.length} messages and ${users.length} users');
          emit(loadedState);

          // Handle unread messages after emitting the loaded state
          final unreadMessages = filteredMessages
              .where((message) =>
                  message.receiverId == event.userId &&
                  !_isMessageRead(message))
              .toList();

          final int unreadCount = unreadMessages.length;
          print('Found $unreadCount unread messages');

          if (unreadCount > 0) {
            // Emit unread count after a short delay to ensure UI updates
            await Future.delayed(const Duration(milliseconds: 100));
            emit(UnreadMessagesLoaded(unreadCount));
          }

          if (unreadMessages.isNotEmpty) {
            _showNotificationForNewUnreadMessages(unreadMessages, event.userId);
          }
        },
      );
    } catch (e, stackTrace) {
      print('❌ Error in _onFetchAllMessages: $e');
      print('Stack trace: $stackTrace');
      emit(MessageFailure(e.toString()));
    }
  }

  // Notify for every new unread message that hasn't been notified yet
  void _showNotificationForNewUnreadMessages(
      List<MessageEntity> messages, String currentUserId) {
    for (final message in messages) {
      if (!_notifiedMessageIds.contains(message.id)) {
        _notifiedMessageIds.add(message.id);
        _showNotification(message, currentUserId);
      }
    }
  }

  Future<void> _onDeleteMessageThread(
    DeleteMessageThreadEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(MessageLoading());

    final result = await deleteMessageThreadUsecase(DeleteMessageThreadParams(
      userId: event.userId,
      otherUserId: event.otherUserId,
    ));

    result.fold(
      (failure) {
        emit(MessageFailure(_mapFailureToMessage(failure)));
      },
      (_) {
        emit(MessageThreadDeleted());
      },
    );
  }

  Future<void> _onMarkMessageAsRead(
    MarkMessageAsReadEvent event,
    Emitter<MessageState> emit,
  ) async {
    final result = await markMessageReadUsecase(MarkMessageReadParams(
      messageId: event.messageId,
    ));

    result.fold(
      (failure) {
        emit(MessageFailure(_mapFailureToMessage(failure)));
      },
      (_) {
        // ✅ Track message as read
        _readMessages.add(event.messageId);

        // ✅ Update unread messages count
        if (state is UnreadMessagesLoaded) {
          final currentCount = (state as UnreadMessagesLoaded).unreadCount;
          emit(UnreadMessagesLoaded(currentCount > 0 ? currentCount - 1 : 0));
        } else {
          emit(UnreadMessagesLoaded(0));
        }

        emit(MessageMarkedAsRead());
      },
    );
  }

  Future<void> _onFetchAllUsers(
    FetchAllUsersEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(MessageLoading());

    try {
      final result = await getAllUsersUsecase(NoParams());

      result.fold(
        (failure) {
          emit(MessageFailure(_mapFailureToMessage(failure)));
        },
        (users) {
          if (state is MessageLoaded) {
            final currentState = state as MessageLoaded;
            emit(MessageLoaded(
              messages: currentState.messages,
              users: users,
              currentUser: currentState.currentUser,
            ));
          } else {
            emit(UsersLoaded(users));
          }
        },
      );
    } catch (e) {
      emit(MessageFailure(e.toString()));
    }
  }

  String _getSenderName(String senderId, String currentUserId) {
    if (senderId == currentUserId) {
      return "You";
    }

    print('Getting sender name for ID: $senderId');
    print('Current state: ${state.runtimeType}');

    // Use the last loaded state if current state is not MessageLoaded
    final stateToUse =
        state is MessageLoaded ? state as MessageLoaded : _lastLoadedState;

    if (stateToUse != null) {
      print(
          'Available users (${stateToUse.users.length}): ${stateToUse.users.map((u) => '${u.id}: ${u.name}').join(', ')}');

      // First try to find in users list
      final matchingUser = stateToUse.users.firstWhere(
        (user) => user.id == senderId && user.name.isNotEmpty,
        orElse: () => UserModel(
          id: senderId,
          name: '',
          email: '',
          bio: '',
          propic: '',
          accountType: '',
          gender: '',
          age: '',
          hasSeenIntroVideo: false,
        ),
      );

      if (matchingUser.name.isNotEmpty) {
        print('Found user in users list: ${matchingUser.name}');
        return matchingUser.name;
      }

      // If not found in users list, try to find in current user's followers/following
      final currentUser = stateToUse.currentUser;
      print('Checking current user\'s connections...');
      print(
          'Current user followers: ${currentUser.followers.map((f) => '${f.id}: ${f.name}').join(', ')}');
      print(
          'Current user following: ${currentUser.following.map((f) => '${f.id}: ${f.name}').join(', ')}');

      // Check in followers
      final follower = currentUser.followers.firstWhere(
        (f) => f.id == senderId && f.name.isNotEmpty,
        orElse: () => UserModel(
          id: senderId,
          name: '',
          email: '',
          bio: '',
          propic: '',
          accountType: '',
          gender: '',
          age: '',
          hasSeenIntroVideo: false,
        ),
      );

      if (follower.name.isNotEmpty) {
        print('Found user in followers: ${follower.name}');
        return follower.name;
      }

      // Check in following
      final following = currentUser.following.firstWhere(
        (f) => f.id == senderId && f.name.isNotEmpty,
        orElse: () => UserModel(
          id: senderId,
          name: '',
          email: '',
          bio: '',
          propic: '',
          accountType: '',
          gender: '',
          age: '',
          hasSeenIntroVideo: false,
        ),
      );

      if (following.name.isNotEmpty) {
        print('Found user in following: ${following.name}');
        return following.name;
      }

      print('⚠️ User not found in any list. ID: $senderId');
      return 'Unknown User';
    }

    print('⚠️ No state with user data available');
    return 'Unknown User';
  }

  Future<void> _showNotification(
      MessageEntity message, String currentUserId) async {
    final senderName = _getSenderName(message.senderId, currentUserId);
    print('Showing notification from: $senderName (ID: ${message.senderId})');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'message_channel_id', // Channel ID
      'New Messages', // Channel Name
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    // Show part of the message content in the notification
    String messagePreview = message.content;
    if (messagePreview.length > 50) {
      messagePreview = messagePreview.substring(0, 50) + '...';
    }
    String notificationBody = 'From $senderName: $messagePreview';

    await _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'New Message', // Title
      notificationBody, // Message Body
      notificationDetails,
    );
  }

  Future<void> _onDeleteMessage(
    DeleteMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(MessageLoading());

    final result = await deleteMessageUsecase(DeleteMessageParams(
      messageId: event.messageId,
      userId: event.userId,
    ));

    result.fold(
      (failure) {
        emit(MessageFailure(_mapFailureToMessage(failure)));
      },
      (_) {
        emit(MessageDeleted(event.messageId));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    return failure.message;
  }
}
