import 'package:get/get.dart';

class MainController extends GetxController {
  static MainController get to => Get.find();
  
  //final Rx<Agent> agent = Agent().obs;
  
  @override
  void onInit() {
    super.onInit();
    // Initialize any necessary data here
  }
}

// class Agent {
//   final String agentCode;
  
//   Agent({this.agentCode = ''});
  
//   Map<String, dynamic> toJson() => {
//     'agent_code': agentCode,
//   };
  
//   factory Agent.fromJson(Map<String, dynamic> json) {
//     return Agent(
//       agentCode: json['agent_code'] ?? '',
//     );
//   }
// }
