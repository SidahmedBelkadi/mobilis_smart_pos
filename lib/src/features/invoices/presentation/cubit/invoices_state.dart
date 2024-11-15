part of 'invoices_cubit.dart';

sealed class InvoicesState extends Equatable {
  const InvoicesState();

  @override
  List<Object> get props => [];
}

final class InvoicesInitial extends InvoicesState {
  const InvoicesInitial();
}

final class InvoicesWithData extends InvoicesState {
  final List<InvoiceEntity> invoices;

  const InvoicesWithData(this.invoices);

  @override
  List<Object> get props => [invoices];
}

final class GetInvoicesSuccess extends InvoicesWithData {
  final bool hasMoreInvoices;

  const GetInvoicesSuccess(
    super.invoices, {
    required this.hasMoreInvoices,
  });

  @override
  List<Object> get props => [invoices, hasMoreInvoices];
}

final class FetchingMoreInvoices extends InvoicesWithData {
  const FetchingMoreInvoices(super.invoices);

  @override
  List<Object> get props => [invoices];
}

final class GetInvoicesFailure extends InvoicesState {
  final String message;

  const GetInvoicesFailure({required this.message});

  @override
  List<Object> get props => [message];
}

final class GetInvoicesLoading extends InvoicesState {
  const GetInvoicesLoading();
}
