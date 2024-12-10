import 'package:encrypt/encrypt.dart' as encrypt;

class AESHelper {
  static final String key = 'my32lengthsupersecretnooneknows1';

  static String encryptMessage(String plainText) {
    final encryptKey = encrypt.Key.fromUtf8(key); 
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(encryptKey));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}'; 
  }

  static String decryptMessage(String encryptedTextWithIv) {
    final encryptKey = encrypt.Key.fromUtf8(key); 

    final parts = encryptedTextWithIv.split(':');
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encryptedText = parts[1]; 

    final encrypter = encrypt.Encrypter(encrypt.AES(encryptKey));
    final encrypted = encrypt.Encrypted.fromBase64(
        encryptedText); 
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return decrypted; 
  }
}
