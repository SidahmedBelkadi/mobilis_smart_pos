class RasdGenerateContractParamsEntity {
  String? msisdn;
  String contractCode;
  String dsaMessage;

  RasdGenerateContractParamsEntity({
    this.msisdn,
    required this.contractCode,
    required this.dsaMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      "msisdn": msisdn,
      "CC_code": contractCode,
      "message": dsaMessage,
    };
  }
}
