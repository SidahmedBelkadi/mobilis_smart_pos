part of 'rasd_contract_cubit.dart';

sealed class RasdContractState extends Equatable {
  const RasdContractState();

  @override
  List<Object> get props => [];
}

final class RasdContractInitial extends RasdContractState {}

final class RasdEditContractSuccess extends RasdContractState {
  final RasdEditContractResponseEntity rasdEditContractResponseEntity;

  const RasdEditContractSuccess({required this.rasdEditContractResponseEntity});

  @override
  List<Object> get props => [rasdEditContractResponseEntity];
}

final class RasdEditContractFailed extends RasdContractState {
  final String message;

  const RasdEditContractFailed({required this.message});

  @override
  List<Object> get props => [message];
}

final class RasdEditContractLoading extends RasdContractState {}

// ------------- RASD Contract Generation ---------------- //

final class RasdGenerateContractSuccess extends RasdContractState {
  final GenerateContractResponseEntity generateContractResponseEntity;

  const RasdGenerateContractSuccess({required this.generateContractResponseEntity});

  @override
  List<Object> get props => [generateContractResponseEntity];
}

final class RasdGenerateContractFailed extends RasdContractState {
  final String message;

  const RasdGenerateContractFailed({required this.message});

  @override
  List<Object> get props => [message];
}

final class RasdGenerateContractLoading extends RasdContractState {}
