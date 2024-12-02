import 'package:dartz/dartz.dart';
import 'package:mobilis_smart_pos/src/features/invoices/domain/entities/retry_activation_response_entity.dart';

import '../../../../core/error/failure.dart';
import '../entities/invoice_entity.dart';

abstract class InvoicesRepository {
  Future<Either<Failure, List<InvoiceEntity>>> getInvoices({
    required int pdvId,
    required int page,
    required String? query,
  });

  Future<Either<Failure, RetryActivationResponseEntity>> retryActivation({required String id});
}
