import '../../domain/entities/invoice_entity.dart';

class InvoiceModel extends InvoiceEntity {
  const InvoiceModel({
    required super.id,
    required super.contractCode,
    required super.invoiceDate,
    required super.amount,
    required super.status,
    required super.msisdn,
    required super.iccid,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'],
      contractCode: json['contract_code'],
      invoiceDate: json['invoice_date'],
      amount: json['amount'],
      status: json['status'],
      msisdn: json['msisdn'],
      iccid: json['serial_number'],
    );
  }
}
