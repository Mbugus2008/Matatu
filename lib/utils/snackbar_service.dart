import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarService {
 static void showError(String message) {
    if (Get.isSnackbarOpen) return;
    
    // Use default context if Get.context is null
    final context = Get.context ?? Get.key.currentContext;
    if (context == null) {
      Future.delayed(Duration(milliseconds: 300), () => showError(message));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccess(String message) {
     if (Get.isSnackbarOpen) return;
  
  try {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  } catch (e) {
    Future.delayed(Duration(milliseconds: 300), () => showSuccess(message));
  }
}
}
