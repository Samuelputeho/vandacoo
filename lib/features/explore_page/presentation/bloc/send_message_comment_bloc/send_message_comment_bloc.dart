import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/common/entities/message_entity.dart';
import '../../../domain/usecases/send_message.dart';

part 'send_message_comment_event.dart';
part 'send_message_comment_state.dart';

class SendMessageCommentBloc
    extends Bloc<SendMessageCommentEvent, SendMessageCommentState> {
  final SendMessage sendMessageUseCase;

  SendMessageCommentBloc({required this.sendMessageUseCase})
      : super(SendMessageCommentInitial()) {
    on<SendMessageCommentRequestEvent>(_onSendMessage);
  }

  Future<void> _onSendMessage(
    SendMessageCommentRequestEvent event,
    Emitter<SendMessageCommentState> emit,
  ) async {
    emit(SendMessageCommentLoading());

    final result = await sendMessageUseCase(SendMessageUseCaseParams(
      senderId: event.senderId,
      receiverId: event.receiverId,
      content: event.content,
      messageType: event.messageType,
      mediaFile: event.mediaFile,
      mediaUrl: event.mediaUrl,
    ));

    result.fold(
      (failure) => emit(SendMessageCommentFailure(failure.message)),
      (message) => emit(SendMessageCommentSuccess(message)),
    );
  }
}
