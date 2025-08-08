import 'package:equatable/equatable.dart';

class NotificationSettingsState extends Equatable {
  final bool isLoading;
  final bool pushEnabled;
  final String? message;

  const NotificationSettingsState({
    required this.isLoading,
    required this.pushEnabled,
    this.message,
  });

  factory NotificationSettingsState.initial() =>
      const NotificationSettingsState(isLoading: false, pushEnabled: false);

  NotificationSettingsState copyWith({
    bool? isLoading,
    bool? pushEnabled,
    String? message,
  }) {
    return NotificationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      message: message,
    );
  }

  @override
  List<Object?> get props => [isLoading, pushEnabled, message];
}
