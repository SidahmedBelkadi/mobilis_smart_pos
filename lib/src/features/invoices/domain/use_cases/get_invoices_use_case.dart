import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/invoice_entity.dart';
import '../repositories/invoices_repository.dart';

class GetInvoicesUseCase {
  final InvoicesRepository repository;

  GetInvoicesUseCase({required this.repository});

  Future<Either<Failure, List<InvoiceEntity>>> call(
      {required int pdvId, required int page, required String? query}) async {
    return await repository.getInvoices(pdvId: pdvId, page: page, query: query);
  }
}
