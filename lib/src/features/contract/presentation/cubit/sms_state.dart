part of 'sms_cubit.dart';

sealed class SmsState extends Equatable {
  const SmsState();

  @override
  List<Object> get props => [];
}

final class SmsInitial extends SmsState {}

final class TriggerSmsSuccess extends SmsInitial {}

final class TriggerSmsLoading extends SmsInitial {}

final class TriggerSmsFailure extends SmsInitial {
  final String message;

  TriggerSmsFailure({required this.message});

  @override
  List<Object> get props => [message];
}

final class RetryTriggerSmsSuccess extends SmsInitial {}

final class RetryTriggerSmsLoading extends SmsInitial {}

final class RetryTriggerSmsFailure extends SmsInitial {
  final String message;

  RetryTriggerSmsFailure({required this.message});

  @override
  List<Object> get props => [message];
}
