part of 'contract_cubit.dart';

sealed class ContractState extends Equatable {
  const ContractState();

  @override
  List<Object> get props => [];
}

final class ContractInitial extends ContractState {}

// ============ CHECK BEFORE EDIT THE CONTRACT ================= //
final class CheckBeforeEditContractSuccess extends ContractState {
  final String formattedStringWithoutSpaces;

  const CheckBeforeEditContractSuccess({required this.formattedStringWithoutSpaces});

  @override
  List<Object> get props => [formattedStringWithoutSpaces];
}

final class CheckBeforeEditContractFailed extends ContractState {
  final String message;

  const CheckBeforeEditContractFailed({required this.message});

  @override
  List<Object> get props => [message];
}

final class CheckBeforeEditContractLoading extends ContractState {}

//================== EDIT THE CONTRACT ================= //
final class EditContractSuccess extends ContractState {
  final EditContractResponseEntity editContractResponseEntity;

  const EditContractSuccess({required this.editContractResponseEntity});

  @override
  List<Object> get props => [editContractResponseEntity];
}

final class EditContractFailed extends ContractState {
  final String message;

  const EditContractFailed({required this.message});

  @override
  List<Object> get props => [message];
}

final class EditContractLoading extends ContractState {}

//================== ATTRIBUTE MSISDN ================= //
final class GenerateContractSuccess extends ContractState {
  final GenerateContractResponseEntity generateContractResponseEntity;

  const GenerateContractSuccess({required this.generateContractResponseEntity});

  @override
  List<Object> get props => [generateContractResponseEntity];
}

final class GenerateContractFailed extends ContractState {
  final String message;

  const GenerateContractFailed({required this.message});

  @override
  List<Object> get props => [message];
}

final class GenerateContractLoading extends ContractState {}
