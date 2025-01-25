part of 'rasd_sms_cubit.dart';

sealed class RasdSmsState extends Equatable {
  const RasdSmsState();

  @override
  List<Object> get props => [];
}

final class RasdSmsInitial extends RasdSmsState {}

final class RasdTriggerSmsSuccess extends RasdSmsInitial {}

final class RasdTriggerSmsFailed extends RasdSmsInitial {
  final String message;

  RasdTriggerSmsFailed({required this.message});

  @override
  List<Object> get props => [message];
}

final class RasdTriggerSmsLoading extends RasdSmsInitial {}
