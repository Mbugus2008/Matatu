import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/agent.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/decorations/input.dart';
import 'package:t_matatu/init.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/pages/home.dart';
import 'package:t_matatu/controllers/TypesController.dart';
import 'package:t_matatu/controllers/header.dart';
import 'package:t_matatu/models/agents.dart';
import 'package:t_matatu/providers/db.dart';
import 'package:t_matatu/reports/controller.dart';
import 'package:t_matatu/utils/snackbar_service.dart';
import 'package:t_matatu/utils/updater.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final Rx<TextEditingController> username = TextEditingController().obs;
  final TextEditingController password = TextEditingController();
  final RxBool loggingin = false.obs;

  @override
  void initState() {
    super.initState();
    getuser();
    //Get.find<MainController>().getDeviceInfo();
  }

  Future<void> getuser() async {
    final un = await Get.find<MainController>().getPreference('username');
    if (un != null) username.value.text = un.toString();
  }

  Future<void> login(String username, String password) async {
    try {
      loggingin.value = true;
      final value = await db_Provider().getagent(Agent.columns, Agent.tableagents, username);
      if (value != null) {
        final agent = Agent.fromMap(value);
        try {
          if(agent.Status != 2){
            SnackbarService.showError('Account Inactive');
            return;
          }
          String pass = AgentController().decrypt(agent.Password ?? "");
          if ( pass == password) {
            await _handleSuccessfulLogin(agent, username);
          } else 
          {
            SnackbarService.showError('Invalid Username / Password');
          }
        } catch (e) {
          SnackbarService.showError('Decryption error. Please contact support');
          print('Decryption error: $e');
        }
      } else {
        SnackbarService.showError('Invalid Username / Password');
      }
    } catch (e,stackTrace) {
      
      stackTrace.printError();
      
      _showErrorSnackbar(e.toString());
    } finally {
      loggingin.value = false;
    }
  }



  Future<void> _handleSuccessfulLogin(Agent agent, String username) async {
    try {
    final mainController = Get.find<MainController>();
    final headerController = Get.find<HeaderController>();
    final transTypeController = Get.find<TransTypeController>();
    final reportController = Get.find<ReportController>();

    mainController.agent.value = agent;

    //await headerController.gettodaystrans();
     mainController.savePreference('username', username);
    password.clear();

     mainController.getPreference("printer");

    transTypeController.start();
    upload(); // async fire-and-forget

     reportController.gettodaysdate();

    Get.off(() => HomePage());
     Future.delayed(const Duration(seconds: 2), () {
        Get.find<UpdateController>().checkForUpdate();
      });
  } catch (e) {
    debugPrint("Login flow failed: $e");
    Get.snackbar("Error", "Login process failed. Please try again.");
  }
  }
  void _showErrorSnackbar(String message) {
    SnackbarService.showError(message);
  }
  @override
  Widget build(BuildContext context) {
    final logoValue = Get.find<MainController>().config?.value.logo;
    final logo = logoValue ?? "";

    return Scaffold(
      //backgroundColor: const Color.fromARGB(255, 240, 240, 240),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          elevation: 20,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: const BorderSide(color: Color.fromARGB(255, 77, 179, 139), width: 1),
          ),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image:   AssetImage(logo),
                fit: BoxFit.cover,
                opacity: 0.1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Obx(() => TextFormField(
                    controller: username.value,
                    decoration: input.inputdecoration("User Name", const Icon(Icons.email)),
                  )),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: password,
                    obscureText: true,
                    decoration: input.inputdecoration("Password", const Icon(Icons.lock)),
                  ),
                  const SizedBox(height: 20),
                  Obx(() => loggingin.value
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () => login(username.value.text, password.text),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.verified_user),
                            SizedBox(width: 8.0),
                            Text('Login'),
                          ],
                        ),
                      ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
