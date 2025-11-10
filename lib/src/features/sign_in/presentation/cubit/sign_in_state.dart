part of 'sign_in_cubit.dart';

sealed class SignInState extends Equatable {
  const SignInState();

  @override
  List<Object> get props => [];
}

final class SignInInitial extends SignInState {}

final class SignInSuccessful extends SignInState {
  final SignInResponseEntity signInResponseEntity;

  const SignInSuccessful({required this.signInResponseEntity});

  @override
  List<Object> get props => [signInResponseEntity];
}

final class SignInFailed extends SignInState {
  final String message;

  const SignInFailed({required this.message});

  @override
  List<Object> get props => [message];
}

final class SignInLoading extends SignInState {}

final class ObsecureClicked extends SignInState {
  final bool isObsecure;

  const ObsecureClicked({required this.isObsecure});

  @override
  List<Object> get props => [isObsecure];
}

final class DisableButton extends SignInState {
  final bool isDisabled;

  const DisableButton({required this.isDisabled});

  @override
  List<Object> get props => [isDisabled];
}

final class EnableButton extends SignInState {
  final bool isDisabled;

  const EnableButton({required this.isDisabled});

  @override
  List<Object> get props => [isDisabled];
}

// ----------- VERIFY OTP --------------- //
final class OTPSuccessful extends SignInState {
  final SignInOTPResponseEntity signInOTPResponseEntity;

  const OTPSuccessful({required this.signInOTPResponseEntity});

  @override
  List<Object> get props => [signInOTPResponseEntity];
}

final class OTPFailed extends SignInState {
  final String message;

  const OTPFailed({required this.message});

  @override
  List<Object> get props => [message];
}

final class OTPLoading extends SignInState {}

// ----------- APPROVE THE CONTRACT --------------- //
final class ApproveContractSuccessful extends SignInState {
  const ApproveContractSuccessful();

  @override
  List<Object> get props => [];
}

final class ApproveContractFailed extends SignInState {
  final String message;

  const ApproveContractFailed({required this.message});

  @override
  List<Object> get props => [message];
}

final class ApproveContractLoading extends SignInState {}
