// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/providers/logger.dart';
import 'package:t_matatu/utils/snackbar_service.dart';
import 'dart:convert';


class ApiClient extends ChangeNotifier {
   final LoggerService logger = Get.find();
  String baseUrl = "http://trimline.co.ke:4005/City/api/";
  //String baseUrl = "http://192.168.100.47:898/api";
  //String baseUrl = "http://192.168.1.118:898/api";
  //String baseUrl = "http://192.168.100.54:898/api";

  Future<http.Response> postdata(String url, String? data) async {
    http.Response? r = http.Response("", 200);
    try {
String urls  = '${Get.find<MainController>().config?.value.apiBaseUrl}$url';

      logger.info(urls);
      logger.info("out: $data");
      
 
   
final rawHeader = {
  'Content-Type': 'application/json',
  'X-Client-Identifier': Get.find<MainController>().config?.value.clientId,
};
logger.info(rawHeader.toString());
// Convert to Map<String, String> by replacing nulls with empty string (or remove them)
final header = rawHeader.map(
  (key, value) => MapEntry(key, value ?? ''),
);

      r = await http.post(
          Uri.parse(
              urls),
          body: data,
          headers:header   );
          
   
      logger.info( 'url: $url, status code: ${r.statusCode}');
      logger.info(  'url: ${url}body: ${r.body}');
      
      if (r.statusCode != 200) {
        logger.error (r.statusCode.toString());
        logger.error (r.body);
        
      }
      
    } catch (e, stackTrace) {
      logger.error("API failed", error: e, stackTrace: stackTrace);
      rethrow; // Let the caller handle the error
    }
    return await Future.value(r);
  }
}

class ApiService extends GetxService {
  Future<ApiService> init() async {
    // Initialize your API service here
    print('ApiService initialized');
    return this;
  }

  // ... other API methods
}


// class AesDecryption {
//   static final key = encrypt.Key.fromUtf8('kOFq5NYMkfiYPayzs3GntbP2mCT+39WLDcnuLJ5Rsrg='); // 32 bytes
//   static final iv = encrypt.IV.fromUtf8('1234567890abcdef'); // 16 bytes

//   static String decrypt(String encryptedBase64) {
//     final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
//     final encrypted = encrypt.Encrypted.fromBase64(encryptedBase64);
//     final decrypted = encrypter.decrypt(encrypted, iv: iv);
//     return decrypted; // This is the original plaintext
//   }
// }