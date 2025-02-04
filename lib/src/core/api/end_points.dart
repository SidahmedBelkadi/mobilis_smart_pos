class EndPoints {
  EndPoints._();

  // ============== BASE URLS =================== //

  static const String ocrBaseUrl = String.fromEnvironment("OCR_BASE_URL");

  static const String baseUrl = "https://ms-pos.mobilis.dz/api2/app";

  // static const String baseUrl = "http://172.20.10.5:3002/api2/app";

  // ============== APK ================== //
  static const String downloadApk = "https://ms-pos.mobilis.dz/apk";

  // ============== AUTH =================== //
  static const String signUp = "$baseUrl/sign";
  static const String signIn = "$baseUrl/login";
  static const String refreshToken = "$baseUrl/refresh";
  static const String verifyOTP = "$baseUrl/login/verify-otp";
  static const String approveContract = "$baseUrl/login/approval";
  static const String resetPasswordOTP = "$baseUrl/password/request-otp";
  static const String resetPassword = "$baseUrl/password/update";
  static const String signOut = "$baseUrl/logout";

  // ================= PDV =============== //
  static const String profile = "$baseUrl/pdv";
  static const String invoices = "$baseUrl/pdv/invoices/filtred";
  static const String updatePDV = "$baseUrl/employee";
  static const String uploadPDV = "$baseUrl/file/employee";
  static const String pdvFolder = "$baseUrl/folder/employee";
  static const String retryActivation = "$baseUrl/retry/edit";

  // ================== CLIENT ================= //
  static const String checkBeforeEditContract = "$baseUrl/contract/check-before-edit";
  static const String editContract = "$baseUrl/contract/edit";
  static const String rasdEditContract = "$baseUrl/contract-rasd/edit";
  static const String generateContrcat = "$baseUrl/contract/attributeMSISDN";
  static const String rasdGenerateContrcat = "$baseUrl/contract-rasd/attributeMSISDN";
  static const String rasdTriggerSms = "$baseUrl/contract-rasd/triggerSMS";
  static const String uploadClient = "$baseUrl/file/client";
  static const String uploadClientRasd = "$baseUrl/file/client_rasd";
  static const String getAllOffers = "$baseUrl/subscription-type/all";
  static const String triggerSms = "$baseUrl/contract/triggerSMS";
  static const String retryTriggerSms = "$baseUrl/contract/triggerSMS/retry";

  // static const String retriveCGV = "http://172.20.10.5:3002/api2/subscription-type";

  // ================== OCR =================== //
  static const String processId = "$ocrBaseUrl/process_id";
  static const String processPassport = "$ocrBaseUrl/process_passport";

// ================== app Version check =================== //
  static const String appVersion = "$baseUrl/mobile_version/last";
}
