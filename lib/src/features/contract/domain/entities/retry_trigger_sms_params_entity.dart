class RetryTriggerSmsParamsEntity {
  final int id;
  final String msisdnAPN;

  const RetryTriggerSmsParamsEntity({
    required this.id,
    required this.msisdnAPN,
  });

  Map<String, dynamic> toJson() {
    return {
      "invoiceID": id,
      "msisdnAPN": msisdnAPN,
    };
  }
}
