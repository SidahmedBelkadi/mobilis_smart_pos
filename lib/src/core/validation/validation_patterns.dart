class ValidationPatterns {
  static const String namePattern = r'^.{3,100}$';
  static const String phonePattern = r'^6 (\d{2} ){3}\d{2}$';
  static const String passwordPattern = r'^.{8,100}$';
  static const String strongPasswordPattern =
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@#$!%*?&])[A-Za-z\d@#$!%*?&]{8,}$';
  static const String emailPattern = r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';
  static const String addressPattern = r'^.{5,200}$';
  static const String yearsOfExperiencePattern = r'^\d+$';
  static const String ninPattern = r'^\d{18}$';
  static const String documentNumberPattern = r'^\d{9}$';
  static const String issuingCountryPattern = r'^.{5,30}$';
  static const String issuingPlacePattern = r'^.{5,30}$';
  static const String datePattern = r'^\d{4}-\d{2}-\d{2}$';
  static const String documentTypePattern = r'^(ID Card|Passport)$';
  static const String bloodGroupPattern = r'^(A|B|AB|O)[+-]$';
  static const String genderPattern = r'^(Homme|Femme)$';
  static const String commercialRegisterPattern = r'^\d{10,20}$';
  static const String codeOfCommercialRegisterPattern = r'^\d{10,20}$';
  static const String taxIdentificationNumberPattern = r'^\d{15}$';
  static const String companyNamePattern = r'^.{4,50}$';
  static const String wilayaPattern = r'^.{1,}$';
  static const String dairaPattern = r'^.{1,}$';
}
