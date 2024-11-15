import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  static final key = encrypt.Key.fromLength(32);
  static final iv = encrypt.IV.fromLength(16);

  static String encryptData(String data) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.encrypt(data, iv: iv).base64;
  }

  static String decryptData(String encryptedData) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.decrypt64(encryptedData, iv: iv);
  }
}
