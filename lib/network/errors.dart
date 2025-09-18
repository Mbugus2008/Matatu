import 'package:get/get.dart';

class Errors {
  void report(Exception ex) {
    ex.printError();
  }
}
