part of 'check_client_cubit.dart';

sealed class CheckClientState extends Equatable {
  const CheckClientState();

  @override
  List<Object?> get props => [];
}

final class CheckClientInitial extends CheckClientState {}

final class CheckClientLoading extends CheckClientState {}

final class CheckClientEligible extends CheckClientState {}

/// The client cannot be activated: the sale stops here.
final class CheckClientRefused extends CheckClientState {
  /// CLIENT_BLACKLISTED, DOCUMENT_EXPIRED, CLIENT_HAS_REACHED_SIM_LIMIT...
  final String message;
  final String? limit;

  const CheckClientRefused({required this.message, this.limit});

  @override
  List<Object?> get props => [message, limit];
}

/// Network or server problem: the check can be retried.
final class CheckClientFailed extends CheckClientState {
  final String message;

  const CheckClientFailed({required this.message});

  @override
  List<Object?> get props => [message];
}
