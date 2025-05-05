import 'package:equatable/equatable.dart';

// ignore: must_be_immutable
class GenerateContractParamsEntity extends Equatable {
  int invoiceId;
  int subsId;

  GenerateContractParamsEntity({
    required this.invoiceId,
    required this.subsId,
  });

  @override
  List<Object?> get props => [invoiceId, subsId];
}
