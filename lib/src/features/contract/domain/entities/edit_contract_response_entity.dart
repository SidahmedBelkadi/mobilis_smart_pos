import 'package:equatable/equatable.dart';

class EditContractResponseEntity extends Equatable {
  final String message;
  final String msisdn;

  const EditContractResponseEntity({
    required this.message,
    required this.msisdn,
  });

  @override
  List<Object?> get props => [
        message,
        msisdn,
      ];
}
