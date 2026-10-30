/// Body of POST /contract/check-client, sent right after the ID document is read.
class CheckClientParamsEntity {
  /// ISO date: the backend decides from it if the client is a minor.
  final String birthDate;

  /// Null for RASD documents, which have none.
  final String? nin;
  final String documentType;
  final String documentNumber;

  /// ISO date.
  final String issueDate;

  /// A minor's document must be sent as a list, even without the parent's.
  final bool isMinor;

  const CheckClientParamsEntity({
    required this.birthDate,
    required this.nin,
    required this.documentType,
    required this.documentNumber,
    required this.issueDate,
    required this.isMinor,
  });

  Map<String, dynamic> toJson() {
    final document = {
      if (nin != null) "NIN": nin,
      "Document_type": documentType,
      "Document_number": documentNumber,
      "Issue_date": issueDate,
    };
    return {
      "client": {"Birth_date": birthDate},
      "civil_documents": isMinor ? [document] : document,
    };
  }
}
