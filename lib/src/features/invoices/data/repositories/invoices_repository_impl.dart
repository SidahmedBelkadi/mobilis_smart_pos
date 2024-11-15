import 'package:dartz/dartz.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/networking/network_info.dart';
import '../../../../core/utils/handlers/error_handler.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/invoices_repository.dart';
import '../data_sources/invoices_remote_data_source.dart';

class InvoicesRepositoryImpl implements InvoicesRepository {
  final NetworkInfo networkInfo;
  final InvoicesRemoteDataSource remoteDataSource;

  InvoicesRepositoryImpl(
      {required this.networkInfo, required this.remoteDataSource});

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getInvoices(
      {required int pdvId, required int page, String? query}) async {
    if (await networkInfo.isConnected) {
      try {
        final List<InvoiceEntity> invoices = await remoteDataSource.getInvoices(
            pdvId: pdvId, page: page, query: query);
        return Right(invoices);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: ErrorHandler.getErrorMessage(e)));
      }
    } else {
      return const Left(
          NoInternetConnectionFailure(message: 'noInternetConnection'));
    }
  }
}
