import 'package:equatable/equatable.dart';

class CheckBeforeEditContractResponseEntity extends Equatable {
  final String formattedStringWithoutSpaces;

  const CheckBeforeEditContractResponseEntity({required this.formattedStringWithoutSpaces});

  @override
  List<Object?> get props => [formattedStringWithoutSpaces];
}
