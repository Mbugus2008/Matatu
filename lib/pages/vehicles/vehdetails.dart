import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:t_matatu/controllers/vehicles/vehicles.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';

class VehDetails extends GetView<VehiclesController> {
  final Vehicles vehicle;

  const VehDetails({Key? key, required this.vehicle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              vehicle.Vehicle_Number ?? 'N/A',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _showVehicleInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildVehicleInfoCard(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => await controller.refreshVehicleDetails(vehicle.Vehicle_Number),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      _buildTransactionsList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildTotalsCard(),
    );
  }

  Widget _buildVehicleInfoCard() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      color: Colors.blue.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Fleet Number', vehicle.Fleet_No ?? 'N/A'),
            _buildInfoRow('Vehicle Type', vehicle_type_desc.desc[vehicle.Vehicle_Type] ?? 'Unknown'),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    return Obx(() => _buildGroupedTransactionListView(controller.vehcollections));
  }

  Widget _buildGroupedTransactionListView(List<dynamic> transactions) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions available'));
    }

    final groupedTransactions = _groupTransactions(transactions);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final entry = groupedTransactions.entries.elementAt(index);
        return _buildTransactionGroup(entry.key, entry.value);
      },
    );
  }

  Map<String, List<dynamic>> _groupTransactions(List<dynamic> transactions) {
    return transactions.fold<Map<String, List<dynamic>>>({}, (map, transaction) {
      final key = '${transaction.OTTN}-${transaction.Agent_Code}';
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(transaction);
      return map;
    });
  }

  Widget _buildTransactionGroup(String key, List<dynamic> transactions) {
    final ottn = key.split('-')[0];
    final agentCode = key.split('-')[1];
    final totalAmount = transactions.fold<double>(0.0, (sum, transaction) => sum + (transaction.Amount ?? 0));

    return Obx(() => Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(Get.context!).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'RCPT#: $ottn',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Agent: $agentCode',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Total: ${NumberFormat("#,##0.00", "en_US").format(totalAmount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    '${transactions.length} transaction${transactions.length != 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.expand_more, color: Colors.blue),
          children: [
            Container(
              color: Colors.grey[100],
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) => _buildTransactionItem(transactions[index]),
              ),
            ),
          ],
          onExpansionChanged: (expanded) => controller.toggleExpansion(key),
          initiallyExpanded: controller.isExpanded(key),
        ),
      ),
    ));
  }

  Widget _buildTransactionItem(dynamic transaction) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  transaction.Description ?? 'No Description',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Text(
                  _formatDateTime(transaction.Transaction_Time),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount:',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                NumberFormat("#,##0.00", "en_US").format(transaction.Amount ?? 0),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    if (dateTime is DateTime) {
      return DateFormat('HH:mm:ss').format(dateTime);
    }
    if (dateTime is String) {
      try {
        final parsedDate = DateTime.parse(dateTime);
        return DateFormat('HH:mm:ss').format(parsedDate);
      } catch (e) {
        return dateTime;
      }
    }
    return 'N/A';
  }

  Widget _buildTotalsCard() {
    return Obx(() {
      final totalAmount = controller.vehcollections
          .fold<double>(0, (sum, transaction) => sum + (transaction.Amount ?? 0));

      return Card(
        elevation: 4,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                NumberFormat("#,##0.00", "en_US").format(totalAmount),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  void _showVehicleInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vehicle Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Fleet Number', vehicle.Fleet_No ?? 'N/A'),
              _buildInfoRow('Vehicle Type', vehicle_type_desc.desc[vehicle.Vehicle_Type] ?? 'Unknown'),
              // Add more vehicle information here
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}