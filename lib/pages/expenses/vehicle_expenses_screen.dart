// ignore_for_file: public_member_api_docs, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/expenses/expense_controller.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/models/expenses/expenses.dart';
import 'package:t_matatu/models/expenses/vehicle_expenses.dart';
import 'package:t_matatu/utils/snackbar_service.dart';

/// Vehicle expenses, captured offline first.
///
/// Rows are written to SQLite straight away and only pushed to Business
/// Central by Post All, so capturing an expense never depends on the network.
/// Everything still unsynced is badged "Local" and counted in the bottom bar.
class VehicleExpensesScreen extends StatefulWidget {
  const VehicleExpensesScreen({super.key});

  @override
  State<VehicleExpensesScreen> createState() => _VehicleExpensesScreenState();
}

class _VehicleExpensesScreenState extends State<VehicleExpensesScreen> {
  static const Color _background = Color(0xFFFDF6EE);
  static const Color _cardSurface = Color(0xFFF2F3F7);
  static const Color _hairline = Color(0xFFE4DFD7);
  static const Color _mutedText = Color(0xFF7B7367);
  static const Color _warning = Color(0xFFDD7A32);
  static const Color _badgeBackground = Color(0xFFFBE3D0);
  static const Color _badgeText = Color(0xFFB45B1E);
  static const Color _syncBar = Color(0xFFFDF3E1);
  static const Color _postButton = Color(0xFF6E6459);
  static const Color _fallbackAccent = Color(0xFFC0503C);

  final Set<String> _collapsedDays = {};
  final Set<String> _collapsedCreators = {};

  bool _loading = true;
  bool _posting = false;
  List<Vehicle_Expenses> _rows = [];

  @override
  void initState() {
    super.initState();
    // initState runs inside the build phase, so the first load has to wait for
    // it to finish before touching state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Color _accent() {
    final hex = Get.find<MainController>().config?.value.theme?.primaryColor;
    if (hex == null) return _fallbackAccent;
    final clean = hex.replaceFirst('#', '');
    final full = clean.length == 6 ? 'FF$clean' : clean;
    return Color(int.parse(full, radix: 16));
  }

  /// Who captured the entry. BC records the BC user on insert, but the device
  /// still has to send something so the row is attributable offline.
  String get _createdBy =>
      Get.find<MainController>().agent.value.Agent_Code ?? '';

  List<Vehicle_Expenses> get _pending =>
      _rows.where((row) => !row.sent).toList();

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      // The expense types are needed to label the rows, so make sure the
      // lookup table is populated before rendering.
      await Get.find<ExpenseController>().getall();
      final rows = await Vehicle_Expenses().getall();
      rows.sort((a, b) =>
          (b.Date ?? DateTime(0)).compareTo(a.Date ?? DateTime(0)));
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      SnackbarService.showError('Could not load expenses');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Actions ───

  Future<void> _openForm({Vehicle_Expenses? existing}) async {
    if (Get.find<ExpenseController>().all.isEmpty) {
      await Get.find<ExpenseController>().getall();
    }
    if (!mounted) return;
    if (Get.find<ExpenseController>().all.isEmpty) {
      SnackbarService.showError(
          'No expense types available — check the connection');
      return;
    }

    final row = await showDialog<Vehicle_Expenses>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ExpenseFormDialog(
        existing: existing,
        createdBy: _createdBy,
        accent: _accent(),
      ),
    );
    if (row == null) return;

    try {
      await row.saveLocal();
      SnackbarService.showSuccess(
          existing == null ? 'Expense saved' : 'Expense updated');
    } catch (e) {
      SnackbarService.showError('Could not save the expense');
    } finally {
      await _load();
    }
  }

  Future<void> _postAll() async {
    final pending = _pending;
    if (pending.isEmpty) return;
    setState(() => _posting = true);
    var synced = 0;
    try {
      synced = await Vehicle_Expenses.postPending();
      if (synced == 0) {
        SnackbarService.showError(
            'Nothing was posted — check the connection and try again');
      } else if (synced < pending.length) {
        SnackbarService.showError(
            '$synced posted, ${pending.length - synced} still pending');
      } else {
        SnackbarService.showSuccess('$synced expense(s) posted');
      }
    } catch (e) {
      SnackbarService.showError('Post failed: $e');
    } finally {
      if (mounted) setState(() => _posting = false);
      await _load();
    }
  }

  Future<void> _postOne(Vehicle_Expenses row) async {
    setState(() => _posting = true);
    try {
      final synced = await Vehicle_Expenses.postRows([row]);
      if (synced == 0) {
        SnackbarService.showError(
            'Business Central did not accept this expense');
      } else {
        SnackbarService.showSuccess('Expense posted');
      }
    } catch (e) {
      SnackbarService.showError('Post failed: $e');
    } finally {
      if (mounted) setState(() => _posting = false);
      await _load();
    }
  }

  /// Removes the row from the device only. There is no delete endpoint for
  /// this page, so an expense that was already posted stays in BC.
  Future<void> _delete(Vehicle_Expenses row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text(
            '${_expenseLabel(row.Expense)} • ${_money(row.Amount ?? 0)} will be '
            'removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Vehicle_Expenses.deleteLocal(row.Code);
    await _load();
  }

  // ─── Formatting ───

  String _money(double value) => NumberFormat('#,##0.00').format(value);

  String _date(DateTime value) => DateFormat('dd-MMM-yyyy').format(value);

  String _dayLabel(DateTime day) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    if (day == start) return 'Today';
    if (day == start.subtract(const Duration(days: 1))) return 'Yesterday';
    return _date(day);
  }

  /// The dropdown stores an expense code, so the readable name has to come
  /// from the Expenses lookup table.
  String _expenseLabel(String? code) {
    if (code == null || code.isEmpty) return 'Expense';
    for (final Expenses type in Get.find<ExpenseController>().all) {
      if (type.Code == code) return type.Description ?? code;
    }
    return code;
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _accent(),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Vehicle Expenses'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: _accent(),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      bottomNavigationBar: _pending.isEmpty ? null : _buildSyncBar(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_rows.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      color: _accent(),
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        children: _buildGroups(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 56, color: _mutedText),
            const SizedBox(height: 16),
            const Text('No expenses captured yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Tap Add to record one. It is saved on the phone and posted to '
              'Business Central when you are online.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _mutedText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncBar() {
    final count = _pending.length;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 12, 12 + MediaQuery.of(context).padding.bottom),
      color: _syncBar,
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: _warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              count == 1 ? '1 expense not synced' : '$count expenses not synced',
              style: const TextStyle(
                  color: _warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 15),
            ),
          ),
          FilledButton.icon(
            onPressed: _posting ? null : _postAll,
            style: FilledButton.styleFrom(
              backgroundColor: _postButton,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            icon: _posting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_upload_outlined, size: 18),
            label: const Text('Post All'),
          ),
        ],
      ),
    );
  }

  /// Day group, then a group per user who captured within that day.
  List<Widget> _buildGroups() {
    final byDay = <DateTime, List<Vehicle_Expenses>>{};
    for (final row in _rows) {
      final date = row.Date ?? DateTime.now();
      final day = DateTime(date.year, date.month, date.day);
      byDay.putIfAbsent(day, () => []).add(row);
    }

    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final widgets = <Widget>[];

    for (final day in days) {
      final dayRows = byDay[day]!;
      final dayKey = day.toIso8601String();
      final collapsed = _collapsedDays.contains(dayKey);
      widgets.add(_buildDayHeader(day, dayRows, collapsed));
      if (collapsed) continue;

      final byCreator = <String, List<Vehicle_Expenses>>{};
      for (final row in dayRows) {
        final creator = (row.Created_By ?? '').trim();
        byCreator
            .putIfAbsent(creator.isEmpty ? 'Unknown' : creator, () => [])
            .add(row);
      }

      final creators = byCreator.keys.toList()..sort();
      for (final creator in creators) {
        final creatorRows = byCreator[creator]!;
        final creatorKey = '$dayKey|$creator';
        final creatorCollapsed = _collapsedCreators.contains(creatorKey);

        widgets.add(_buildCreatorHeader(
            creator, creatorRows, creatorKey, creatorCollapsed));
        if (creatorCollapsed) continue;

        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 2),
          child: Column(
            children: creatorRows.map(_buildExpenseCard).toList(),
          ),
        ));
      }

      widgets.add(const SizedBox(height: 14));
    }

    return widgets;
  }

  Widget _buildDayHeader(
      DateTime day, List<Vehicle_Expenses> rows, bool collapsed) {
    final total = rows.fold<double>(0, (sum, row) => sum + (row.Amount ?? 0));
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() {
          if (collapsed) {
            _collapsedDays.remove(day.toIso8601String());
          } else {
            _collapsedDays.add(day.toIso8601String());
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _hairline),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_dayLabel(day)} (${rows.length})',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                _money(total),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              Icon(
                collapsed
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_up,
                color: _mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatorHeader(String creator, List<Vehicle_Expenses> rows,
      String creatorKey, bool collapsed) {
    final total = rows.fold<double>(0, (sum, row) => sum + (row.Amount ?? 0));
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => setState(() {
          if (collapsed) {
            _collapsedCreators.remove(creatorKey);
          } else {
            _collapsedCreators.add(creatorKey);
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _hairline)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Created By: $creator',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                _money(total),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              Icon(
                collapsed
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_up,
                color: _mutedText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseCard(Vehicle_Expenses row) {
    final description = (row.Description ?? '').trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _expenseLabel(row.Expense),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              if (!row.sent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _badgeBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Local',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _badgeText),
                  ),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: _mutedText),
                tooltip: 'Expense actions',
                onSelected: (value) {
                  if (value == 'post') _postOne(row);
                  if (value == 'edit') _openForm(existing: row);
                  if (value == 'delete') _delete(row);
                },
                itemBuilder: (_) => [
                  if (!row.sent)
                    const PopupMenuItem(
                        value: 'post', child: Text('Post now')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Wrap(
              spacing: 18,
              runSpacing: 4,
              children: [
                _detail('Date:', row.Date == null ? '-' : _date(row.Date!)),
                _detail('Created By:', (row.Created_By ?? '-').trim()),
                _detail('Amount:', _money(row.Amount ?? 0)),
              ],
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                description,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4A4A4A)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: Color(0xFF4A4A4A)),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Add / edit sheet. The vehicle is deliberately not asked for: this page's
/// BC records never carry one, and the expense is attributed to the user who
/// captured it.
class _ExpenseFormDialog extends StatefulWidget {
  const _ExpenseFormDialog({
    this.existing,
    required this.createdBy,
    required this.accent,
  });

  final Vehicle_Expenses? existing;
  final String createdBy;
  final Color accent;

  @override
  State<_ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<_ExpenseFormDialog> {
  late DateTime _date;
  late final TextEditingController _dateCtrl;
  String? _expense;
  late final TextEditingController _description;
  late final TextEditingController _amount;

  static String _formatDate(DateTime value) =>
      DateFormat('dd-MMM-yyyy').format(value);

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _date = existing?.Date ?? DateTime.now();
    _dateCtrl = TextEditingController(text: _formatDate(_date));
    _expense = existing?.Expense;
    _description = TextEditingController(text: existing?.Description ?? '');
    _amount = TextEditingController(
        text: existing?.Amount == null
            ? ''
            : existing!.Amount!.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateCtrl.text = _formatDate(picked);
    });
  }

  void _save() {
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', ''));
    if (_expense == null || _expense!.isEmpty) {
      SnackbarService.showError('Kindly select the Expense');
      return;
    }
    if (amount == null || amount <= 0) {
      SnackbarService.showError('Enter an amount greater than zero');
      return;
    }

    // Hand the row back to the list, which owns the local save.
    Navigator.of(context).pop(
      Vehicle_Expenses(
        Key: widget.existing?.Key,
        Code: widget.existing?.Code,
        Vehicle_No: widget.existing?.Vehicle_No,
        Date: _date,
        DateSpecified: true,
        Expense: _expense,
        Description: _description.text.trim(),
        Created_By: widget.createdBy,
        Amount: amount,
        AmountSpecified: true,
        Fleet_No: widget.existing?.Fleet_No,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final types = Get.find<ExpenseController>().all;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'Add Expense' : 'Edit Expense',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _dateCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                labelText: 'Date',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined, size: 20),
                  onPressed: _pickDate,
                ),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _expense,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Expense'),
              hint: const Text('Expense'),
              items: types
                  .map((type) => DropdownMenuItem<String>(
                        value: type.Code,
                        child: Text(
                          type.Description ?? type.Code ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _expense = value),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              readOnly: true,
              initialValue: widget.createdBy,
              decoration: const InputDecoration(labelText: 'Created By'),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6E6459),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 12),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
