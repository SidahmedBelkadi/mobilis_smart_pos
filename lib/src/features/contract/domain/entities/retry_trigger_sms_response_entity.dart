import 'package:equatable/equatable.dart';

class RetryTriggerSmsResponseEntity extends Equatable {
  final int subsId;
  final int invoiceId;
  final int clientId;
  final String contractCode;

  const RetryTriggerSmsResponseEntity({
    required this.subsId,
    required this.invoiceId,
    required this.clientId,
    required this.contractCode,
  });

  @override
  List<Object?> get props => [subsId, invoiceId, clientId, contractCode];
}
