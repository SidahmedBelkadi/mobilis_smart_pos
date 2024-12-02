import 'package:equatable/equatable.dart';

class RetryActivationResponseEntity extends Equatable {
  final String formattedStringSms;
  final String generateContractUrl;

  const RetryActivationResponseEntity({
    required this.formattedStringSms,
    required this.generateContractUrl,
  });

  @override
  List<Object?> get props => [formattedStringSms, generateContractUrl];
}
