import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

class NoInternetConnectionFailure extends Failure {
  const NoInternetConnectionFailure({required super.message});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// The client cannot be activated (blacklisted, expired document, SIM limit...).
class ClientRefusedFailure extends Failure {
  /// Active SIM limit, sent with CLIENT_HAS_REACHED_SIM_LIMIT.
  final String? limit;

  const ClientRefusedFailure({required super.message, this.limit});

  @override
  List<Object?> get props => [message, limit];
}
