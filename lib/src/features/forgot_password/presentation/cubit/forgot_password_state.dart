part of 'forgot_password_cubit.dart';

sealed class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object> get props => [];
}

final class ForgotPasswordInitial extends ForgotPasswordState {}

// ------ REQUEST OTP ------------//

final class ResetPasswordOTPSuccess extends ForgotPasswordState {
  final String message;

  const ResetPasswordOTPSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

final class ResetPasswordOTPFailure extends ForgotPasswordState {
  final String message;

  const ResetPasswordOTPFailure({required this.message});

  @override
  List<Object> get props => [message];
}

final class ResetPasswordOTPLoading extends ForgotPasswordState {}

// ------ RESET PASSWORD  ------------//

final class ResetPasswordSuccess extends ForgotPasswordState {
  final String message;

  const ResetPasswordSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

final class ResetPasswordFailure extends ForgotPasswordState {
  final String message;

  const ResetPasswordFailure({required this.message});

  @override
  List<Object> get props => [message];
}

final class ResetPasswordLoading extends ForgotPasswordState {}

final class ObsecureClicked extends ForgotPasswordState {
  final bool isObsecure;

  const ObsecureClicked({required this.isObsecure});

  @override
  List<Object> get props => [isObsecure];
}
