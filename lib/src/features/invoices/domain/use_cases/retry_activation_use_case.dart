import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/features/invoices/domain/entities/retry_activation_response_entity.dart';

import '../../../../core/error/failure.dart';
import '../repositories/invoices_repository.dart';

class RetryActivationUseCase {
  final InvoicesRepository repository;

  RetryActivationUseCase({required this.repository});

  Future<Either<Failure, RetryActivationResponseEntity>> call({required String id}) async {
    return await repository.retryActivation(id: id);
  }
}
