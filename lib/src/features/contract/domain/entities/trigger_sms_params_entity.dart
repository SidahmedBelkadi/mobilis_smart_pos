class TriggerSmsParamsEntity {
  final int id;
  final String msisdnAPN;
  final String formattedSmsString;

  const TriggerSmsParamsEntity({
    required this.id,
    required this.msisdnAPN,
    required this.formattedSmsString,
  });

  Map<String, dynamic> toJson() {
    return {
      "invoiceID": id,
      "msisdnAPN": msisdnAPN,
      "formattedString": formattedSmsString,
    };
  }
}
