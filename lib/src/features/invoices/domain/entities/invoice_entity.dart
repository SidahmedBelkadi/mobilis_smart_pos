import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class InvoiceEntity extends Equatable {
  final String contractCode;
  final String invoiceDate;
  final int? amount;
  final String status;
  final String? msisdn;
  final String? iccid;

  const InvoiceEntity({
    required this.contractCode,
    required this.invoiceDate,
    required this.amount,
    required this.status,
    required this.msisdn,
    required this.iccid,
  });

  @override
  List<Object?> get props => [contractCode, invoiceDate, amount, status, msisdn];

  String get formattedInvoiceDate {
    final dateTime = DateTime.tryParse(invoiceDate);
    if (dateTime == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
  }

  String get formattedInvoiceDateInArabic {
    final dateTime = DateTime.tryParse(invoiceDate);
    if (dateTime == null) return '';
    return DateFormat('yyyy/MM/dd HH:mm:ss').format(dateTime);
  }
}
