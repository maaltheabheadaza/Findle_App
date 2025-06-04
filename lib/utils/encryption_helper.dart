import 'package:encrypt/encrypt.dart';

class EncryptionHelper {
  static final _key = Key.fromUtf8('my32lengthsupersecretnooneknows1'); // must be 32 characters
  static final _iv = IV.fromLength(16); // static IV for simplicity; can be random for stronger security
  static final _encrypter = Encrypter(AES(_key));

  static String encryptText(String text) {
    return _encrypter.encrypt(text, iv: _iv).base64;
  }

  static String decryptText(String encrypted) {
    return _encrypter.decrypt64(encrypted, iv: _iv);
  }
}
