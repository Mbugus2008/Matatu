import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:t_matatu/bluetooth/bluetoothManager.dart';
import 'package:t_matatu/controllers/agent.dart';
import 'package:t_matatu/controllers/expenses/expense_controller.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/models/Reversal.dart';
import 'package:t_matatu/models/agents.dart';
import 'package:t_matatu/models/expenses/expenses.dart';
import 'package:t_matatu/models/summary/Tsummary.dart';
import 'package:t_matatu/models/summary/TsummaryDetails.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/pages/Reversals/ReversalsList.dart';
import 'package:t_matatu/pages/TwoTabScreen.dart';
import 'package:t_matatu/providers/db.dart';
import 'package:t_matatu/reports/Daily%20Summary.dart';
import 'package:t_matatu/reports/controller.dart';
import 'package:t_matatu/reports/receipts.dart';
import 'package:t_matatu/utils/updater.dart';

import '../bluetooth/bluetoothscans.dart';

class CustomDrawer extends StatelessWidget {
  CustomDrawer({super.key});

  Color? _primaryColor(BuildContext context) {
    final hex = Get.find<MainController>().config?.value.theme?.primaryColor;
    if (hex == null) return null;
    final clean = hex.replaceFirst('#', '');
    final full = clean.length == 6 ? 'FF$clean' : clean;
    return Color(int.parse(full, radix: 16));
  }

  Color _iconColor(BuildContext context) =>
      _primaryColor(context) ?? Theme.of(context).primaryColor;

  Future<String> _getVersion() async {
    final info = await PackageInfo.fromPlatform();
    final clientName =
        Get.find<MainController>().CurrentClient?.value.clientName ?? 'Matatu';
    return 'v${info.version} © $clientName';
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required BuildContext context,
    Color? iconColor,
  }) {
    final color = iconColor ?? _iconColor(context);
    return ListTile(
      leading: Icon(icon, color: color),
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      dense: true,
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    final color = _primaryColor(context) ?? Colors.blueGrey;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Get.find<MainController>().getPreference("printer").toString();
    final primary = _primaryColor(context);
    // Hide Receipts & Z Report for Depot/Fuel operators (account_type 3)
    final isNotDepotFuel =
        Get.find<MainController>().agent.value.Account_type != 3;
    // Client-specific menu (Hires, Waybill, Dispatch & Fuel, etc.)
    final clientMenu =
        Get.find<MainController>().CurrentClient?.value.clientMenu();
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // --- Printer Section ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                const Expanded(
                  flex: 1,
                  child: Text('Printer: '),
                ),
                Expanded(
                  flex: 3,
                  child: Obx(() => Text(Get.find<BluetoothManager>()
                          .selectedPrinter
                          .value
                          ?.deviceName ??
                      '')),
                ),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.to(() => const bluetoothScanresults());
                    },
                    child: const Text("Set"),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black26),

          // --- Menu Section ---
          _buildSectionHeader('MENU', context),
          _buildTile(
            icon: Icons.monetization_on,
            title: 'Expenses',
            context: context,
            onTap: () {
              final expenses = Get.find<ExpenseController>().all;
              Get.to(() => _ExpensesListScreen(expenses: expenses));
            },
          ),

          _buildTile(
            icon: Icons.undo_outlined,
            title: 'Reversals',
            context: context,
            iconColor: Colors.red.shade400,
            onTap: () async {
              await Reversal().getreversals();
              Get.to(() => ReversalListScreen(
                    reversal: Get.find<ReversalController>().reversals.toList(),
                  ));
            },
          ),
          if (clientMenu != null) ...[
            ...clientMenu,
          ],
          const Divider(height: 1, indent: 16, endIndent: 16),
          // --- Reports Section ---
          _buildSectionHeader('REPORTS', context),
          if (isNotDepotFuel)
            _buildTile(
              icon: Icons.receipt_long,
              title: 'Receipts',
              context: context,
              onTap: () {
                ReportController().gettransbydate(DateTime.now());
                Get.find<ReportController>().selectedDate?.value =
                    DateTime.now();
                Get.to(() => const ReceiptReport());
              },
            ),
          _buildTile(
            icon: Icons.summarize,
            title: 'Daily Summary',
            context: context,
            onTap: () {
              TsummaryDetails().getall();
              Tsummary().getall();
              Get.to(() => const SummaryReport());
            },
          ),
          _buildTile(
            icon: Icons.directions_bus,
            title: 'Vehicle Collections',
            context: context,
            onTap: () {
              ReportController().gettransbydate(DateTime.now());
              Get.find<ReportController>().selectedDate?.value = DateTime.now();
              Get.to(() => const TwoTabScreen());
            },
          ),
          _buildTile(
            icon: Icons.account_balance_wallet,
            title: 'Collections & Expenses',
            context: context,
            onTap: () {
              TsummaryDetails().getall();
              Tsummary().getall();
              Get.to(() => const SummaryReport());
            },
          ),
          if (isNotDepotFuel)
            _buildTile(
              icon: Icons.print,
              title: 'Z Report',
              context: context,
              onTap: () {
                TsummaryDetails().getall();
                Tsummary().getall();
                Get.to(() => const SummaryReport());
              },
            ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // --- Settings Section ---
          _buildSectionHeader('SETTINGS', context),
          _buildTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            context: context,
            onTap: () => _showChangePasswordDialog(context),
          ),
          _buildTile(
            icon: Icons.system_update,
            title: 'Check for Updates',
            context: context,
            onTap: () => Get.find<UpdateController>().checkForUpdate(),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // --- Version Footer ---
          FutureBuilder<String>(
            future: _getVersion(),
            builder: (context, snapshot) {
              final version = snapshot.data ?? '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    version,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Old Password'),
            ),
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            TextField(
              controller: confirmPass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (newPass.text != confirmPass.text) {
                  Get.snackbar('Error', 'Passwords do not match');
                  return;
                }
                final agentCode =
                    Get.find<MainController>().agent.value.Agent_Code;
                // NAV's Users page encrypts the Password field itself on
                // every Modify - sending an already-encrypted value makes BC
                // store a double-encrypted blob and login breaks. So send the
                // PLAINTEXT here; NAV stores the single-encrypted value.
                final encrypted = AgentController().encrypt(newPass.text);
                final body = jsonEncode({
                  'Agent_Code': agentCode,
                  'Password': newPass.text,
                });
                final r = await ApiClient().postdata('changepassword', body);
                if (r.statusCode != 200) {
                  Get.snackbar('Error', 'Failed to change password');
                  return;
                }
                final map = jsonDecode(r.body) as Map<String, dynamic>;
                if (map['Code'] != 0) {
                  Get.snackbar('Error',
                      map['Desc']?.toString() ?? 'Failed to change password');
                  return;
                }
                // Update the local agents table too - login compares the
                // entered password against the LOCAL copy, so without this
                // the new password would not work until a full re-sync.
                final local = await Get.find<db_Provider>().getagent(
                    Agent.columns, Agent.tableagents, agentCode ?? '');
                if (local != null) {
                  final ag = Agent.fromMap(local);
                  ag.Password = encrypted;
                  await Get.find<db_Provider>().insert(Agent.tableagents, ag);
                }
                Get.find<MainController>().agent.value.Password = encrypted;
                Get.back();
                Get.snackbar('Success', 'Password changed');
              } catch (e) {
                Get.snackbar('Error', 'Failed to change password: $e');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Simple expenses list screen
class _ExpensesListScreen extends StatelessWidget {
  final RxList<Expenses> expenses;
  const _ExpensesListScreen({required this.expenses});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: Obx(
        () => expenses.isEmpty
            ? const Center(child: Text('No expenses'))
            : ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final e = expenses[index];
                  return ListTile(
                    title: Text(e.Description ?? ''),
                    trailing: Text(e.Code ?? ''),
                  );
                },
              ),
      ),
    );
  }
}
