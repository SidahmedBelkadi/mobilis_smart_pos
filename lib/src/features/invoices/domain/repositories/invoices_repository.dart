import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/invoice_entity.dart';

abstract class InvoicesRepository {
  Future<Either<Failure, List<InvoiceEntity>>> getInvoices({
    required int pdvId,
    required int page,
    required String? query,
  });
}
