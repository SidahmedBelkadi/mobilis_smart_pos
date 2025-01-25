import 'package:equatable/equatable.dart';

class RasdEditContractResponseEntity extends Equatable {
  final int subscriptionID;
  final String contractCode;

  const RasdEditContractResponseEntity({
    required this.subscriptionID,
    required this.contractCode,
  });

  @override
  List<Object?> get props => [subscriptionID, contractCode];
}
