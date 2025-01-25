import 'package:equatable/equatable.dart';

class EditContractResponseEntity extends Equatable {
  final int subscriptionId;
  final int invoiceId;
  final int clientId;
  final String contractCode;
  final String message;
  final String contractMessage;

  const EditContractResponseEntity({
    required this.subscriptionId,
    required this.invoiceId,
    required this.clientId,
    required this.contractCode,
    required this.message,
    required this.contractMessage,
  });

  @override
  List<Object?> get props => [
        subscriptionId,
        invoiceId,
        clientId,
        contractCode,
        message,
        contractMessage,
      ];
}
