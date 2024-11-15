import 'package:equatable/equatable.dart';

// ignore: must_be_immutable
class GenerateContractParamsEntity extends Equatable {
  final int clientId;
  final int invoiceId;
  final int subsId;
  String? msisdn;
  final String contractCode;
  String? dsaMessage;

  GenerateContractParamsEntity({
    required this.clientId,
    required this.invoiceId,
    required this.subsId,
    this.msisdn,
    required this.contractCode,
    this.dsaMessage,
  });

  @override
  List<Object?> get props =>
      [clientId, invoiceId, subsId, msisdn, contractCode];
}
