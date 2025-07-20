import 'package:equatable/equatable.dart';

class RasdEditContractResponseEntity extends Equatable {
  final String message;

  const RasdEditContractResponseEntity({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}
