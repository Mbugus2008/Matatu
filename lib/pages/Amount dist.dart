import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/models/trantypes.dart';

import '../controllers/TypesController.dart';
import '../controllers/header.dart';
import '../controllers/vehicles/vehicles.dart';
import '../models/Transaction.dart' as tmatatu;
import '../models/vehicles/vehicle.dart';
import '../providers/logger.dart';

class Distribute extends StatefulWidget {
  const Distribute({super.key});

  @override
  State<Distribute> createState() => _DistributeState();
}

class _DistributeState extends State<Distribute> {
  final TextEditingController recamount = TextEditingController();
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    // Keep the distribute button in step with the typed amount.
    recamount.addListener(_refresh);
  }

  @override
  void dispose() {
    recamount.removeListener(_refresh);
    recamount.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  double get _received => double.tryParse(recamount.text.trim()) ?? 0;

  // ─── Design tokens ───
  static const _primary = Color(0xFF1E88E5);
  static const _primaryDark = Color(0xFF1565C0);
  static const _ink = Color(0xFF1F2937);
  static const _muted = Color(0xFF6B7280);
  static const _outline = Color(0xFFE3E8EF);
  static const _surface = Color(0xFFF4F6FA);
  static const _success = Color(0xFF2E7D32);
  static const _warning = Color(0xFFB45309);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Obx(() {
          final vehicle = Get.find<VehiclesController>().Currentvehicle.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vehicle?.Vehicle_Number ?? 'Distribute',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(
                vehicle == null
                    ? 'Spread the amount received'
                    : 'Fleet ${vehicle.Fleet_No ?? '-'}',
                style: TextStyle(
                    fontSize: 11, color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          );
        }),
      ),
      body: Column(
        children: [
          _buildHeroCard(),
          // One builder for the whole body: list, tiles and total stay in sync
          // from a single controller notification.
          Expanded(
            child: GetBuilder<TransTypeController>(
              init: Get.find<TransTypeController>(),
              builder: (controller) {
                if (controller.loading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final types = controller.vehicleTrantypes
                    .where((t) => t.Name != null)
                    .toList()
                  // Biggest expected amount first, matching the order the
                  // allocation fills in.
                  ..sort(TransTypeController.compareByExpectedDesc);
                return Column(
                  children: [
                    _buildSummaryStrip(types),
                    Expanded(child: _buildTransactionList(types)),
                    _buildFooterRow(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset:
          true, // Allow resizing when the keyboard appears
    );
  }

  /// Hero: one compact row — amount received and the one action that matters.
  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: TextField(
                  controller: recamount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: _ink),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    prefixText: 'KES ',
                    prefixStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _muted),
                    hintText: 'Amount received',
                    hintStyle:
                        TextStyle(fontSize: 15, color: Color(0xFFB6BEC9)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              // Disabled until there is something to spread.
              onPressed: _received > 0 ? _applyDistribution : null,
              icon: const Icon(Icons.call_split, size: 18),
              label: const Text('Distribute'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _primaryDark,
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyDistribution() {
    Get.find<TransTypeController>().distribute(_received);
    FocusScope.of(context).unfocus();
  }

  /// One slim status line instead of two tiles, so the list keeps the space.
  Widget _buildSummaryStrip(List<TranTypes> types) {
    final selected = Get.find<TransTypeController>().get_selected() ?? 0;
    final unallocated = _received - selected;
    final selectedCount = types.where((t) => t.Checked == true).length;
    final warn = unallocated > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Icon(warn ? Icons.error_outline : Icons.done_all,
              size: 14, color: warn ? _warning : _success),
          const SizedBox(width: 6),
          Text(
            'Selected ${_money(selected)}',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: _ink),
          ),
          Text('  ·  ', style: TextStyle(fontSize: 12, color: _muted)),
          Expanded(
            child: Text(
              _received <= 0
                  ? 'Enter the amount received'
                  : (warn
                      ? '${_money(unallocated)} unallocated'
                      : 'Fully allocated'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      _received <= 0 ? _muted : (warn ? _warning : _success)),
            ),
          ),
          Text('$selectedCount / ${types.length}',
              style: const TextStyle(fontSize: 11, color: _muted)),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<TranTypes> types) {
    if (types.isEmpty) {
      return const Center(child: Text('No transaction types for this vehicle'));
    }
    // Plain ListView.builder: lazy, no shrinkWrap, no fixed height — the outer
    // Expanded + GetBuilder supply the scrolling and the rebuilds.
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: types.length,
      itemBuilder: (context, index) =>
          _buildTransactionCard(context, types[index], index),
    );
  }

  Widget _buildTransactionCard(
      BuildContext context, TranTypes transactionType, int index) {
    final selected = transactionType.Checked ?? false;
    final expected = (transactionType.VehicleAmount ?? 0).toDouble();
    final collected = (transactionType.Amounttoday ?? 0).toDouble();
    final balance = (expected - collected).clamp(0, double.infinity).toDouble();
    final paid = expected > 0 && balance <= 0;
    final progress =
        expected <= 0 ? 0.0 : (collected / expected).clamp(0.0, 1.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? _primary.withValues(alpha: 0.55) : _outline,
          width: selected ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: selected ? 0.06 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            _onTransactionCheckboxChanged(context, transactionType, !selected),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _selectDot(selected),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                transactionType.Name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _ink),
                              ),
                            ),
                            if (paid) _pill('PAID', _success),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Expected ${_money(expected)}  ·  Today ${_money(collected)}',
                          style: const TextStyle(fontSize: 11, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildTransactionAmountField(transactionType, selected),
                ],
              ),
              if (expected > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: _outline,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        paid ? _success : _primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectDot(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? _primary : Colors.transparent,
        border: Border.all(
          color: selected ? _primary : const Color(0xFFBBC3CE),
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 15, color: Colors.white)
          : null,
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5),
      ),
    );
  }

  /// Amounts are shown (and written back) with two decimals so the field text
  /// never reads like `2500.0`.
  String _money(num value) => NumberFormat('#,##0.00', 'en_US').format(value);

  String _amountText(num value) => value.toStringAsFixed(2);

  /// Right-hand side of a card: an editable amount for the types that are
  /// entered by hand, otherwise the auto-calculated amount.
  Widget _buildTransactionAmountField(
      TranTypes transactionType, bool selected) {
    final editable = transactionType.VehicleAmount == 0 ||
        transactionType.Code == 'SAVINGS' ||
        TranTypes.isCrewSavings(transactionType.Code);

    if (!editable) {
      return SizedBox(
        width: 96,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _money(transactionType.Amountedited ?? 0),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: selected ? _primaryDark : _muted,
              ),
            ),
            const Text('auto', style: TextStyle(fontSize: 10, color: _muted)),
          ],
        ),
      );
    }

    return SizedBox(
      width: 108,
      child: TextField(
        focusNode: transactionType.FocusNodes,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        controller: transactionType.eAmount,
        textAlign: TextAlign.right,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: _primaryDark),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: _surface,
          prefixText: 'KES ',
          prefixStyle: const TextStyle(fontSize: 11, color: _muted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primary, width: 1.6),
          ),
        ),
        onChanged: (value) {
          final parsed = double.tryParse(value.trim());
          if (parsed == null && value.trim().isNotEmpty) {
            _log('Invalid amount "$value" for ${transactionType.Code}');
            return;
          }
          transactionType.Amountedited = parsed ?? 0;
          // Refresh the tiles and the total as the user types.
          Get.find<TransTypeController>().update();
        },
      ),
    );
  }

  void _log(String message) {
    try {
      Get.find<LoggerService>().warning('Distribute: $message');
    } catch (_) {
      // Logger not ready — ignore
    }
  }

  /// Sticky bottom bar: the running total and the one commit action.
  Widget _buildFooterRow() {
    final selected = Get.find<TransTypeController>().get_selected() ?? 0;
    final unallocated = _received - selected;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (unallocated > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: _warning),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_money(unallocated)} not allocated yet',
                          style: const TextStyle(fontSize: 11, color: _warning),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total allocated',
                          style: TextStyle(fontSize: 11, color: _muted)),
                      Text(
                        _money(selected),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _ink),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _confirming || selected <= 0 ? null : _confirm,
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Confirm'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 22),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Applies the allocation and returns to the receipt. Guarded so a double tap
  /// cannot create the lines twice.
  Future<void> _confirm() async {
    setState(() => _confirming = true);
    try {
      Get.find<HeaderController>().createlines();
      Get.find<HeaderController>().curTran = tmatatu.Trans().obs;
      Get.find<VehiclesController>().Currentvehicle = Vehicles().obs;
      Get.back();
    } catch (e) {
      _log('confirm failed: $e');
      if (mounted) setState(() => _confirming = false);
    }
  }

  void _onTransactionCheckboxChanged(
      BuildContext context, TranTypes transactionType, bool? value) {
    // Toggle by identity — the displayed list is filtered and re-ordered, so an
    // index would point at the wrong row.
    Get.find<TransTypeController>().toggleType(transactionType);

    final vehicleAmount = transactionType.VehicleAmount ?? 0;
    final collected = transactionType.Amounttoday ?? 0;

    if (value == true) {
      if (collected == vehicleAmount && vehicleAmount > 0) {
        _showConfirmationDialog(context, transactionType);
      } else {
        final balance = vehicleAmount > 0
            ? (vehicleAmount - collected).clamp(0, double.infinity).toDouble()
            : 0.0;
        transactionType.Amountedited = balance;
        transactionType.eAmount.text = _amountText(balance);
      }
    } else {
      transactionType.Amountedited = 0.0;
      transactionType.eAmount.text = _amountText(0);
    }

    transactionType.eAmount.selection = TextSelection(
      baseOffset: 0,
      extentOffset: transactionType.eAmount.text.length,
    );
    FocusScope.of(context).requestFocus(transactionType.FocusNodes);
    Get.find<TransTypeController>().update();
  }

  void _showConfirmationDialog(BuildContext context, TranTypes types) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${types.Name} '),
          content: Text('${types.Name} is paid in full today. Add?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    ).then((value) {
      if (value == true) {
        final amount = (types.VehicleAmount ?? 0).toDouble();
        types.Amountedited = amount;
        types.eAmount.text = _amountText(amount);
      } else {
        types.Checked = false;
      }
      Get.find<TransTypeController>().update();
    });
  }
}
