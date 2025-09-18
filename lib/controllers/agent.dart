import 'package:encrypt/encrypt.dart';
import 'package:get/get.dart';
import 'package:t_matatu/models/agents.dart';

class AgentController extends GetxController {
  RxList<Agent> agent = <Agent>[].obs;

final String iv = "1234567890abcdef";
final String keys = "kOFq5NYMkfiYPayzs3GntbP2mCT+39WLDcnuLJ5Rsrg="; 

   String decrypt(String encryptedText) {
    try {
      // Convert the Base64 key to bytes
      final key = Key.fromBase64(keys);
      final initializationVector = IV.fromUtf8(iv);
      // Create an encrypter instance with AES algorithm in CBC mode
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      // Create an encrypted object from the Base64-encoded string
      final encrypted = Encrypted.fromBase64(encryptedText);
      // Decrypt the data
      final decrypted = encrypter.decrypt(encrypted, iv: initializationVector);
      return decrypted;
    } catch (e) {
      // Handle any errors that occur during decryption
   print(e);
      return '';
    }
  }

}
