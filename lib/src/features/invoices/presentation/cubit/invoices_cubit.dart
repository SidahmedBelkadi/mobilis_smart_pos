import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/use_cases/get_invoices_use_case.dart';

part 'invoices_state.dart';

class InvoicesCubit extends Cubit<InvoicesState> {
  final GetInvoicesUseCase useCase;
  final SmartPosLocalStorage authenticationLocalDataSource;

  InvoicesCubit({
    required this.useCase,
    required this.authenticationLocalDataSource,
  }) : super(const InvoicesInitial());

  int currentPage = 0;
  bool isFetching = false;
  bool hasMoreInvoices = true;

  Future<void> getInvoices(
      {bool isFirstTime = false,
      bool isFetchingMore = false,
      String? query}) async {
    if (isFetching) return;
    isFetching = true;

    if (isFirstTime) {
      emit(const GetInvoicesLoading());
      currentPage = 0;
      hasMoreInvoices = true;
    } else if (isFetchingMore && state is InvoicesWithData) {
      emit(FetchingMoreInvoices((state as InvoicesWithData).invoices));
    }

    // Fetch the saved login credentials asynchronously
    final savedCredentials =
        authenticationLocalDataSource.getSavedLoginCredentials();
    if (savedCredentials == null || savedCredentials.userId == null) {
      emit(const GetInvoicesFailure(message: 'unexpectedError'));
      isFetching = false;
      return;
    }

    final failureOrInvoices = await useCase(
        page: currentPage, pdvId: savedCredentials.userId!, query: query);

    failureOrInvoices.fold((failure) {
      emit(GetInvoicesFailure(message: failure.message));
    }, (invoices) {
      if (invoices.isEmpty) {
        hasMoreInvoices = false;
      } else {
        currentPage = currentPage + 9;
      }

      if (isFirstTime) {
        emit(GetInvoicesSuccess(
          invoices,
          hasMoreInvoices: hasMoreInvoices,
        ));
      } else if (isFetchingMore && state is InvoicesWithData) {
        emit(GetInvoicesSuccess(
          (state as InvoicesWithData).invoices + invoices,
          hasMoreInvoices: hasMoreInvoices,
        ));
      } else {
        emit(GetInvoicesSuccess(
          invoices,
          hasMoreInvoices: hasMoreInvoices,
        ));
      }
    });

    isFetching = false;
  }

  void searchInvoices(String query) {
    getInvoices(isFirstTime: true, query: query);
  }
}
