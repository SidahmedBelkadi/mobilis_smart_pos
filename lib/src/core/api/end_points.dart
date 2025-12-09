import 'package:flutter_dotenv/flutter_dotenv.dart';

class EndPoints {
  EndPoints._();

  // ============== BASE URLS =================== //

  static const String ocrBaseUrl = String.fromEnvironment("OCR_BASE_URL");

  static String baseUrl = dotenv.env['BASE_URL_PRE_PROD'] ?? "";
  static bool get isApi1 => baseUrl.contains('api1');

  // ============== APK ================== //
  static const String downloadApk = "https://ms-pos.mobilis.dz/apk";

  // ============== AUTH =================== //
  static String signUp = "$baseUrl/sign";
  static String signIn = "$baseUrl/login";
  static String refreshToken = "$baseUrl/refresh";
  static String verifyOTP = "$baseUrl/login/verify-otp";
  static String approveContract = "$baseUrl/login/approval";
  static String resetPasswordOTP = "$baseUrl/password/request-otp";
  static String resetPassword = "$baseUrl/password/update";
  static String signOut = "$baseUrl/logout";

  // ================= PDV =============== //
  static String profile = "$baseUrl/pdv";
  static String invoices = "$baseUrl/pdv/invoices/filtred";
  static String updatePDV = "$baseUrl/employee";
  static String uploadPDV = "$baseUrl/file/employee";
  static String pdvFolder = "$baseUrl/folder/employee";
  static String retryActivation = "$baseUrl/retry/edit";
  static String getBanners = "$baseUrl/folder/banners";
  static String getPdvContract = "$baseUrl/file/consent/last-contract";
  static String signAndApprovePDVContract = "$baseUrl/pdv/consent/sign";
  static String getDynamicCGV = "$baseUrl/subscription-type";

  // ================== CLIENT ================= //
  static String checkBeforeEditContract = "$baseUrl/contract/check-before-edit";
  static String editContract = "$baseUrl/contract/edit";
  static String rasdEditContract = "$baseUrl/contract-rasd/edit";
  static String generateContrcat = "$baseUrl/contract/attributeMSISDN";
  static String rasdGenerateContrcat = "$baseUrl/contract-rasd/attributeMSISDN";
  static String rasdTriggerSms = "$baseUrl/contract-rasd/triggerSMS";
  static String uploadClient = "$baseUrl/file/client";
  static String uploadClientRasd = "$baseUrl/file/client_rasd";
  static String getAllOffers = "$baseUrl/subscription-type/all";
  static String triggerSms = "$baseUrl/contract/triggerSMS";
  static String retryTriggerSms = "$baseUrl/contract/triggerSMS/retry";

  // static const String retriveCGV = "http://172.20.10.5:3002/api2/subscription-type";

  // ================== OCR =================== //
  static const String processId = "$ocrBaseUrl/process_id";
  static const String processPassport = "$ocrBaseUrl/process_passport";

// ================== app Version check =================== //
  static String appVersion = "$baseUrl/mobile_version/last";
}
