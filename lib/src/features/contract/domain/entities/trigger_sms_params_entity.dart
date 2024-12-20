class TriggerSmsParamsEntity {
  final String msisdnAPN;
  final String formattedSmsString;

  const TriggerSmsParamsEntity({required this.msisdnAPN, required this.formattedSmsString});

  Map<String, dynamic> toJson() {
    return {
      "msisdnAPN": msisdnAPN,
      "formattedString": formattedSmsString,
    };
  }
}
