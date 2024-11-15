import 'package:equatable/equatable.dart';

class SignInResponseEntity extends Equatable {
  final String message;
  final bool? isFirstLogin;

  const SignInResponseEntity({
    required this.message,
    required this.isFirstLogin,
  });

  @override
  List<Object?> get props => [message, isFirstLogin];
}
