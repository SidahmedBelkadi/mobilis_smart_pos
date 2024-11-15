import 'package:equatable/equatable.dart';

class GenerateContractResponseEntity extends Equatable {
  final String message;
  final String contractMessage;

  const GenerateContractResponseEntity({required this.message, required this.contractMessage});

  @override
  List<Object?> get props => [message, contractMessage];
}
