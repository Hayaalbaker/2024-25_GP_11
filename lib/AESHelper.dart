import 'package:encrypt/encrypt.dart' as encrypt;

class AESHelper {
  // Static key for AES encryption and decryption (32 bytes for AES-256)
  static final String key = 'my32lengthsupersecretnooneknows1';

  // Encrypts a plain text message using AES
  static String encryptMessage(String plainText) {
    final encryptKey = encrypt.Key.fromUtf8(key); // Key for AES
    final iv = encrypt.IV.fromLength(16); // Generate a new IV each time
    final encrypter = encrypt.Encrypter(encrypt.AES(encryptKey));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // Store the IV along with the encrypted text
    return '${iv.base64}:${encrypted.base64}'; // Prepend the IV to the encrypted message
  }

  // Decrypts an encrypted message using AES
  static String decryptMessage(String encryptedTextWithIv) {
    final encryptKey = encrypt.Key.fromUtf8(key); // Key for AES

    // Extract IV and encrypted text
    final parts = encryptedTextWithIv.split(':');
    final iv = encrypt.IV.fromBase64(parts[0]); // Extract IV
    final encryptedText = parts[1]; // Extract encrypted message

    final encrypter = encrypt.Encrypter(encrypt.AES(encryptKey));
    final encrypted = encrypt.Encrypted.fromBase64(
        encryptedText); // Convert base64 back to Encrypted object
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return decrypted; // Return decrypted message
  }
}
