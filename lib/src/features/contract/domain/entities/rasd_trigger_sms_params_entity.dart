class RasdTriggerSmsParamsEntity {
  final int subscritpionId;
  final String msisdnAPN;

  const RasdTriggerSmsParamsEntity({
    required this.subscritpionId,
    required this.msisdnAPN,
  });

  Map<String, dynamic> toJson() {
    return {
      "msisdnAPN": msisdnAPN,
      "subscriptionID": subscritpionId,
    };
  }
}
