import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/models/Reversal.dart';

import '../../providers/db.dart';

class ReversalListScreen extends StatefulWidget {
  final List<Reversal> reversal;

  ReversalListScreen({required this.reversal, super.key});

  @override
  State<ReversalListScreen> createState() => _ReversalListScreenState();
}

class _ReversalListScreenState extends State<ReversalListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _syncOnOpen();
  }

  Future<void> _syncOnOpen() async {
    await Reversal().syncReversals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A7A7A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Reversals'),
        centerTitle: true,
      ),
      body: Obx(() {
        final List<Reversal> source =
            Get.find<ReversalController>().reversals.isNotEmpty
                ? Get.find<ReversalController>().reversals.toList()
                : widget.reversal;
        final List<Reversal> reversals = source.where(_matchesQuery).toList();

        return RefreshIndicator(
          color: const Color(0xFF7A7A7A),
          backgroundColor: Colors.white,
          onRefresh: _syncOnOpen,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _buildSearchField(),
              const SizedBox(height: 18),
              if (reversals.isEmpty)
                _buildEmptyState()
              else
                ...reversals.map(_buildReversalCard),
            ],
          ),
        );
      }),
    );
  }

  bool _matchesQuery(Reversal reversal) {
    if (_query.trim().isEmpty) {
      return true;
    }

    final String q = _query.toLowerCase().trim();
    final List<String> values = [
      reversal.Receipt_No ?? '',
      reversal.Vehicle ?? '',
      reversal.Account ?? '',
      reversal.Name ?? '',
      reversal.Agent ?? '',
      reversal.Status?.description ?? '',
    ];

    return values.any((value) => value.toLowerCase().contains(q));
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF858585), width: 1.4),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _query = value;
          });
        },
        decoration: const InputDecoration(
          hintText: 'Search reversal by receipt, vehicle, account...',
          prefixIcon: Icon(Icons.search, color: Color(0xFF6B6B6B), size: 26),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 18),
        ),
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF4A4A4A),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4D4D4)),
      ),
      child: const Text(
        'No reversals found.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF6B6B6B),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildReversalCard(Reversal reversal) {
    final DateTime? date = reversal.Transction_Date ?? reversal.Date;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: getTileColor(reversal.Status), width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${reversal.Receipt_No ?? 'No Receipt'}(${reversal.Total_Trans ?? 0})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF535353),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null ? DateFormat('dd-MMM-yy').format(date) : '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4E4E4E),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Text(
                    reversal.Vehicle ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reversal.Total_Amount?.toStringAsFixed(2) ?? '0.00',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3F3F3F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              reversal.Status?.description ?? 'Open',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _statusTextColor(reversal.Status),
              ),
            ),
            if (reversal.Status == STatus.Open)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF4F4F4F)),
                onSelected: (String value) {
                  reversal.Status = STatus.Rejected;
                  reversal.Sent = false;
                  Get.find<db_Provider>().insert(Reversal.table, reversal);
                  Reversal().uploadreversal();
                  Reversal().getreversals();
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'Cancel',
                      child: Row(
                        children: const [
                          Icon(Icons.cancel, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Cancel'),
                        ],
                      ),
                    ),
                  ];
                },
              )
            else
              const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Color getTileColor(STatus? state) {
    switch (state) {
      case STatus.Pending_Approval:
        return const Color(0xFF6E7D8B);
      case STatus.Approved:
        return const Color(0xFF8E8E8E);
      case STatus.Released:
        return const Color(0xFF4A8E59);
      case STatus.Rejected:
        return const Color(0xFFD45A5A);
      case STatus.Open:
        return const Color(0xFF555555);
      default:
        return const Color(0xFF555555);
    }
  }

  Color _statusTextColor(STatus? state) {
    switch (state) {
      case STatus.Rejected:
        return const Color(0xFFC44949);
      case STatus.Released:
        return const Color(0xFF3E8250);
      case STatus.Approved:
        return const Color(0xFF5F5F5F);
      case STatus.Pending_Approval:
        return const Color(0xFF5C6F82);
      case STatus.Open:
      default:
        return const Color(0xFF454545);
    }
  }
}
