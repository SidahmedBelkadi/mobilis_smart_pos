import 'dart:convert';

import 'package:mobilis_smart_pos/src/features/invoices/data/models/retry_activation_response_model.dart';
import 'package:mobilis_smart_pos/src/features/invoices/domain/entities/retry_activation_response_entity.dart';

import '../../../../core/api/dio_consumer.dart';
import '../../../../core/api/end_points.dart';
import '../models/invoice_model.dart';

abstract class InvoicesRemoteDataSource {
  Future<List<InvoiceModel>> getInvoices({
    required int pdvId,
    required int page,
    String? query,
  });

  Future<RetryActivationResponseModel> retryActivation({required String id});
}

class InvoicesRemoteDataSourceImpl implements InvoicesRemoteDataSource {
  final DioConsumer dioConsumer;

  InvoicesRemoteDataSourceImpl({required this.dioConsumer});

  @override
  Future<List<InvoiceModel>> getInvoices({
    required int pdvId,
    required int page,
    String? query,
  }) async {
    final response = query != null
        ? await dioConsumer.get("${EndPoints.invoices}/$pdvId/$page?search=$query")
        : await dioConsumer.get("${EndPoints.invoices}/$pdvId/$page");
    final List<dynamic> decodedResponse = jsonDecode(response);

    final List<InvoiceModel> invoices =
        decodedResponse.map((e) => InvoiceModel.fromJson(e)).toList();
    return invoices;
  }

  @override
  Future<RetryActivationResponseModel> retryActivation({required String id}) async {
    final rawResponse = await dioConsumer.get("${EndPoints.retryActivation}/$id");
    return RetryActivationResponseModel.fromJson(jsonDecode(rawResponse));
  }
}
