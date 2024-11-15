part of 'sign_out_cubit.dart';

sealed class SignOutState extends Equatable {
  const SignOutState();

  @override
  List<Object> get props => [];
}

final class SignOutInitial extends SignOutState {}

final class SignOutSuccessful extends SignOutState {}

final class SignOutUnSuccessful extends SignOutState {
  final String message;

  const SignOutUnSuccessful({required this.message});

  @override
  List<Object> get props => [message];
}

final class SignOutLoading extends SignOutState {}
