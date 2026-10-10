// Dashboard — the M-Branch role-center "Summary" cues (today's numbers):
// cash, M-Pesa and the collections per type. This is the home screen for the
// Manager account type (BC Users: Account type = Manager); it renders inside
// the host Scaffold so the main app bar stays in charge.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/models/dashboard_cues.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/results/results.dart';

class DashboardCuesView extends StatefulWidget {
  const DashboardCuesView({super.key});

  @override
  State<DashboardCuesView> createState() => _DashboardCuesViewState();
}

class _DashboardCuesViewState extends State<DashboardCuesView> {
  static const _primaryGreen = Color(0xFF006B3F);
  static const _mpesaBlue = Color(0xFF0B5FA5);
  static const _fuelAmber = Color(0xFFB45309);
  static const _cashierTeal = Color(0xFF0F766E);

  DashboardCues? _cues;
  DateTime? _updatedAt;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ApiClient().postdata('DashboardCues', '{}');
      if (r.statusCode != 200) {
        throw Exception('Server error ${r.statusCode}');
      }
      final results =
          Results<DashboardCues>.fromJson(r.body, DashboardCues.fromMap);
      if (results.Code != 0 ||
          results.Contents == null ||
          results.Contents!.isEmpty) {
        throw Exception(results.Desc ?? 'Could not load the dashboard');
      }
      if (!mounted) return;
      setState(() {
        _cues = results.Contents!.first;
        _updatedAt = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  String _fmt(num? value) => NumberFormat('#,##0').format(value ?? 0);

  @override
  Widget build(BuildContext context) {
    // Body only - the home screen's Scaffold provides the app bar.
    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Could not load the dashboard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final cues = _cues!;
    final types = <(String, double)>[
      ('Offload', cues.Offload),
      ('Management', cues.Management),
      ('Savings', cues.Savings),
      ('Carwash', cues.Carwash),
      ('Depot Parking', cues.DepotParking),
      ('Expenses', cues.Expenses),
      ('Body', cues.Body),
      ('Insurance', cues.Insurance),
      ('NCC Parking', cues.NccParking),
      ('KNH', cues.Knh),
      ('Savings Crew', cues.SavingsCrew),
      ('Security', cues.Security),
      ('Statutory Sundry', cues.StatutorySundry),
      ('Stones', cues.Stones),
      ('Offload Parking', cues.OffloadParking),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _buildHeader(cues),
          const SizedBox(height: 12),
          _buildCashMpesaCard(cues),
          const SizedBox(height: 18),
          _sectionTitle("Today's Collections"),
          const SizedBox(height: 8),
          _buildCollectionsCard(types),
          if (cues.Cashiers.isNotEmpty) ...[
            const SizedBox(height: 18),
            _sectionTitle('Cashiers · today'),
            const SizedBox(height: 8),
            _buildCashiersCard(cues.Cashiers),
          ],
          const SizedBox(height: 18),
          _sectionTitle('Operations'),
          const SizedBox(height: 8),
          _buildHiresCard(cues),
          const SizedBox(height: 12),
          _buildWaybillCard(cues),
          const SizedBox(height: 12),
          _buildFuelCard(cues),
          const SizedBox(height: 12),
          _buildOnRoute(cues.OnRoute),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey[800]));

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      );

  // ── Cash vs M-Pesa donut ──────────────────────────

  Widget _buildCashMpesaCard(DashboardCues cues) {
    final total = cues.Cash + cues.Mpesa;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Row(
        children: [
          SizedBox(
            width: 124,
            height: 124,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(124, 124),
                  painter: _DonutPainter(
                    cash: cues.Cash,
                    mpesa: cues.Mpesa,
                    cashColor: _primaryGreen,
                    mpesaColor: _mpesaBlue,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 10.5, color: Color(0xFF6F7A71))),
                    Text(
                      NumberFormat.compact().format(total),
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF161D1F)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendRow(_primaryGreen, 'Cash', cues.Cash, total),
                const SizedBox(height: 12),
                _legendRow(_mpesaBlue, 'M-Pesa', cues.Mpesa, total),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, double value, double total) {
    final pct =
        total > 0 ? '  (${(value / total * 100).toStringAsFixed(0)}%)' : '';
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text('$label$pct',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF3F4941))),
        ),
        Text(_fmt(value),
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  // ── Collections by type — sorted bars ─────────────

  Widget _buildCollectionsCard(List<(String, double)> types) {
    final maxValue = types.isEmpty ? 0.0 : types.first.$2;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: _cardDecoration,
      child: Column(
        children: [
          for (var i = 0; i < types.length; i++) ...[
            if (i > 0) const SizedBox(height: 11),
            _barRow(types[i].$1, types[i].$2, maxValue),
          ],
        ],
      ),
    );
  }

  Widget _barRow(String label, double value, double maxValue,
      {String? caption, Color color = _primaryGreen}) {
    final fraction = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 102,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              if (caption != null)
                Text(caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9.5, color: Colors.grey[500])),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Row(
              children: [
                Expanded(
                  flex: (fraction * 1000).round().clamp(1, 1000),
                  child: Container(height: 10, color: color),
                ),
                Expanded(
                  flex: ((1 - fraction) * 1000).round().clamp(1, 1000),
                  child: Container(height: 10, color: const Color(0xFFEEF2F6)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 78,
          child: Text(_fmt(value),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF161D1F))),
        ),
      ],
    );
  }

  // ── Cashiers — today's receipts per agent ─────────

  Widget _buildCashiersCard(List<CashierCue> cashiers) {
    final sorted = [...cashiers]..sort((a, b) => b.Amount.compareTo(a.Amount));
    final maxValue = sorted.isEmpty ? 0.0 : sorted.first.Amount;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: _cardDecoration,
      child: Column(
        children: [
          for (var i = 0; i < sorted.length; i++) ...[
            if (i > 0) const SizedBox(height: 11),
            _barRow(
              sorted[i].Name,
              sorted[i].Amount,
              maxValue,
              caption:
                  '${sorted[i].Count} receipt${sorted[i].Count == 1 ? '' : 's'}',
              color: _cashierTeal,
            ),
          ],
        ],
      ),
    );
  }

  // ── Operations cards (Hires / Waybill / Fuel) ─────

  Widget _opsCard({
    required IconData icon,
    required String title,
    required List<(String, String, Color)> stats,
    required Widget chart,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _primaryGreen),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF161D1F))),
              const Spacer(),
              Text('last 7 days',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stats[i].$1,
                          style: const TextStyle(
                              fontSize: 10.5, color: Color(0xFF6F7A71))),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(stats[i].$2,
                            style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: stats[i].$3)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          chart,
        ],
      ),
    );
  }

  Widget _buildHiresCard(DashboardCues cues) {
    return _opsCard(
      icon: Icons.badge_outlined,
      title: 'Hires · today',
      stats: [
        ('Hires', '${cues.HiresToday}', const Color(0xFF161D1F)),
        ('Amount', _fmt(cues.HiresTodayAmount), _primaryGreen),
        ('Paid', '${cues.HiresPaidToday}', const Color(0xFF2E7D32)),
        ('Unpaid', '${cues.HiresUnpaidToday}', const Color(0xFFC62828)),
      ],
      chart: _miniBars(
        values: [for (final v in cues.HiresByDay) v.toDouble()],
        color: _primaryGreen,
      ),
    );
  }

  Widget _buildWaybillCard(DashboardCues cues) {
    return _opsCard(
      icon: Icons.receipt_long_outlined,
      title: 'Waybill · today',
      stats: [
        ('Entries', '${cues.WaybillsToday}', const Color(0xFF161D1F)),
        ('Target', _fmt(cues.WaybillTargetToday), const Color(0xFF64748B)),
        ('Actual', _fmt(cues.WaybillActualToday), _primaryGreen),
        ('Shortage', _fmt(cues.WaybillShortageToday), const Color(0xFFB91C1C)),
      ],
      chart: _miniBars(
        values: cues.WaybillActualByDay,
        compare: cues.WaybillTargetByDay,
        color: _primaryGreen,
        compareColor: const Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildFuelCard(DashboardCues cues) {
    return _opsCard(
      icon: Icons.local_gas_station_outlined,
      title: 'Fuel · today',
      stats: [
        ('Amount', _fmt(cues.FuelToday), _fuelAmber),
        (
          'Litres',
          NumberFormat('#,##0.##').format(cues.FuelLitresToday),
          const Color(0xFF161D1F)
        ),
      ],
      chart: _miniBars(values: cues.FuelByDay, color: _fuelAmber),
    );
  }

  /// 7 slot mini bar chart (one slot per day, oldest first). When [compare]
  /// is given the two series are drawn side by side (e.g. target vs actual).
  Widget _miniBars({
    required List<double> values,
    List<double>? compare,
    required Color color,
    Color compareColor = const Color(0xFFCBD5E1),
  }) {
    final day = _cues?.Date ?? DateTime.now();
    final days = List.generate(7, (i) => day.subtract(Duration(days: 6 - i)));
    var maxValue = 0.0;
    for (final v in values) {
      if (v > maxValue) maxValue = v;
    }
    if (compare != null) {
      for (final v in compare) {
        if (v > maxValue) maxValue = v;
      }
    }
    double barHeight(double value) =>
        maxValue <= 0 ? 3.0 : (value / maxValue * 46).clamp(3.0, 46.0);
    return Row(
      children: List.generate(7, (i) {
        final value = i < values.length ? values[i] : 0.0;
        final other =
            (compare != null && i < compare.length) ? compare[i] : null;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                SizedBox(
                  height: 46,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (other != null) ...[
                        Expanded(
                          child: Container(
                            height: barHeight(other),
                            decoration: BoxDecoration(
                              color: compareColor.withValues(alpha: 0.45),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
                      Expanded(
                        child: Container(
                          height: barHeight(value),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEEE').format(days[i]),
                  style: TextStyle(
                    fontSize: 9.5,
                    color: i == 6 ? color : Colors.grey[500],
                    fontWeight: i == 6 ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(DashboardCues cues) {
    final day = cues.Date ?? DateTime.now();
    final updated = _updatedAt == null
        ? ''
        : '  ·  updated ${DateFormat('HH:mm').format(_updatedAt!)}';
    return Row(
      children: [
        const Icon(Icons.today, size: 18, color: _primaryGreen),
        const SizedBox(width: 8),
        Text(
          'Today · ${DateFormat('EEE, dd MMM yyyy').format(day)}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Flexible(
          child: Text(updated,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Refresh',
          visualDensity: VisualDensity.compact,
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh, size: 20, color: _primaryGreen),
        ),
      ],
    );
  }

  Widget _buildOnRoute(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_outlined,
              size: 20, color: _primaryGreen),
          const SizedBox(width: 10),
          const Expanded(
            child:
                Text('Vehicles on route today', style: TextStyle(fontSize: 14)),
          ),
          Text('$count',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Two-arc donut: Cash vs M-Pesa share of the day's collections.
class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.cash,
    required this.mpesa,
    required this.cashColor,
    required this.mpesaColor,
  });

  final double cash;
  final double mpesa;
  final Color cashColor;
  final Color mpesaColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = size.width * 0.15;
    final radius = (size.width - stroke) / 2;
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = const Color(0xFFEDF2F7));

    final total = cash + mpesa;
    if (total <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -math.pi / 2;
    final cashSweep = (cash / total) * 2 * math.pi;
    final mpesaSweep = (mpesa / total) * 2 * math.pi;
    canvas.drawArc(
        rect,
        start,
        cashSweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = cashColor);
    start += cashSweep;
    canvas.drawArc(
        rect,
        start,
        mpesaSweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = mpesaColor);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.cash != cash ||
      oldDelegate.mpesa != mpesa ||
      oldDelegate.cashColor != cashColor ||
      oldDelegate.mpesaColor != mpesaColor;
}
