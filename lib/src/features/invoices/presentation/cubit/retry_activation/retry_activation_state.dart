part of 'retry_activation_cubit.dart';

sealed class RetryActivationState extends Equatable {
  const RetryActivationState();

  @override
  List<Object> get props => [];
}

final class RetryActivationInitial extends RetryActivationState {}

// ============== Retry Activation ==================//
final class RetryActivationSuccess extends RetryActivationState {
  final RetryActivationResponseEntity responseEntity;

  const RetryActivationSuccess({required this.responseEntity});

  @override
  List<Object> get props => [responseEntity];
}

final class RetryActivationFailure extends RetryActivationState {
  final String message;

  const RetryActivationFailure({required this.message});

  @override
  List<Object> get props => [message];
}

final class RetryActivationLoading extends RetryActivationState {
  final int id;

  const RetryActivationLoading({required this.id});

  @override
  List<Object> get props => [id];
}
