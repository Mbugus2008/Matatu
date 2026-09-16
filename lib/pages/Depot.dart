import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/Members.dart';
import 'package:t_matatu/controllers/vehicles/vehicles.dart';
import 'package:t_matatu/models/Utils/util.dart';
import 'package:t_matatu/models/expenses/expenses.dart';
import 'package:t_matatu/models/member.dart';
import 'package:t_matatu/models/vehicles/DeportandFuel.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/pages/crew.dart';
import 'package:t_matatu/reports/controller.dart';

class Depot extends StatefulWidget {
  const Depot({super.key});

  @override
  State<Depot> createState() => _DepotState();
}

class _DepotState extends State<Depot> {
  static const Color _primary = Color(0xFF1E88E5);
  static const Color _primaryDark = Color(0xFF1565C0);
  static const Color _ink = Color(0xFF1B2430);
  static const Color _muted = Color(0xFF6B7A8F);
  static const Color _outline = Color(0xFFDCE3EC);
  static const Color _surface = Color(0xFFF7F9FC);
  static const Color _success = Color(0xFF1B9E5A);
  static const Color _danger = Color(0xFFC62828);
  static const Color _warning = Color(0xFFE8A33D);

  late DateTime _selectedDate;
  final TextEditingController _searchController = TextEditingController();
  bool _leaving = false;

  /// True while the "unsaved changes" dialog is on screen, so a second back
  /// press cannot stack a second copy of it.
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    // Follow the date selected on the Dispatch & Fuel summary screen, if any.
    _selectedDate = Get.isRegistered<ReportController>()
        ? (Get.find<ReportController>().selectedDate?.value ?? DateTime.now())
        : DateTime.now();
    // Load after the first frame so no observable is written during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null || picked == _selectedDate) return;
    setState(() => _selectedDate = picked);
    await _fetchData();
  }

  Future<void> _fetchData() async {
    // A new date means a new sheet - drop any active filter so nothing looks
    // like it disappeared.
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      Get.find<DepotController>().filterDepotTrans('');
    }
    await DepotFuel().getNRODefects();
    await DepotFuel().getdata(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DepotController>(
      init: Get.find<DepotController>(),
      // No Obx here: every reactive child below has its own Obx, and the pop
      // guard no longer observes anything now that canPop is always false.
      // (An Obx with no observable read throws in debug builds.)
      builder: (dp) => PopScope(
        // Always intercept. The guard decides whether to leave, so the system
        // back and the app bar arrow both go through the same path and a
        // second press can never stack another confirmation dialog.
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _handleBack(Get.find<DepotController>().dirtyCount.value);
        },
        child: Column(
          children: [
            _buildHeader(dp),
            _buildSearchField(),
            Expanded(child: _buildVehicleList(dp)),
            _buildSaveBar(dp),
          ],
        ),
      ),
    );
  }

  /// Back was pressed: leave straight away when there is nothing pending,
  /// otherwise ask first.
  Future<void> _handleBack(int dirty) async {
    if (_leaving || _confirming) return;
    if (dirty == 0) {
      _leave();
      return;
    }
    _confirming = true;
    try {
      final discard = await _confirmDiscard(dirty);
      if (discard != true || !mounted) return;
      _leave();
    } finally {
      _confirming = false;
    }
  }

  /// Pops the Dispatch page.
  /// Uses [Navigator.pop] rather than `Get.back`: the pop must not be swallowed
  /// by GetX's overlay handling (an open snackbar can absorb `Get.back`), and it
  /// is unconditional, which is what we want now that `canPop` is false.
  void _leave() {
    if (!mounted) return;
    setState(() => _leaving = true);
    Navigator.of(context).pop();
  }

  Future<bool?> _confirmDiscard(int dirty) {
    return Get.dialog<bool>(
      AlertDialog(
        title: const Text('Unsaved changes'),
        content: Text(dirty == 1
            ? '1 vehicle has unsaved dispatch changes. Leave without saving?'
            : '$dirty vehicles have unsaved dispatch changes. Leave without saving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _danger),
            child: const Text('Discard'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildDateSelector(DepotController dp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      border: Border.all(color: _outline),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: _primaryDark),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEE, dd-MMM-yyyy').format(_selectedDate),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _ink),
                        ),
                        const Spacer(),
                        const Icon(Icons.expand_more, size: 18, color: _muted),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(
                () => FilledButton.icon(
                  onPressed: dp.loading.value ? null : _fetchData,
                  icon: dp.loading.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh, size: 18),
                  label: const Text('Get'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          Obx(
            () => dp.loading.value
                ? const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
      child: ListenableBuilder(
        listenable: _searchController,
        builder: (context, _) => TextField(
          controller: _searchController,
          onChanged: (value) =>
              Get.find<DepotController>().filterDepotTrans(value),
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.search, color: _primary, size: 18),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      Get.find<DepotController>().filterDepotTrans('');
                    },
                  ),
            hintText: 'Find vehicle, fleet or crew',
            hintStyle: const TextStyle(fontSize: 12.5),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _outline),
            ),
          ),
        ),
      ),
    );
  }

  /// Date picker + "on route" summary + "all on route" switch.
  Widget _buildHeader(DepotController dp) {
    return Column(
      children: [
        _buildDateSelector(dp),
        Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primaryDark, _primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.local_shipping, color: Colors.white70, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(() {
                  final all = dp.depottrans1.isNotEmpty
                      ? dp.depottrans1.toList()
                      : dp.depottrans.toList();
                  final active = all.where((p0) => p0.On_route == true).length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('On route',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      Text('$active / ${all.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              height: 1.15)),
                    ],
                  );
                }),
              ),
              Obx(
                () => Column(
                  children: [
                    Switch(
                      value: dp.checkall.value,
                      onChanged: dp.checkallvehicles,
                      activeColor: Colors.white,
                      activeTrackColor: _success,
                    ),
                    const Text('All on route',
                        style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleList(DepotController dp) {
    return Obx(() {
      final rows = dp.depottrans;
      if (rows.isEmpty) {
        if (dp.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final query = _searchController.text.trim();
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  query.isEmpty
                      ? Icons.local_shipping_outlined
                      : Icons.search_off,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 10),
                Text(
                  query.isEmpty
                      ? 'No vehicles in the dispatch sheet'
                      : 'No vehicle matches "$query"',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  query.isEmpty
                      ? 'Tap Get to load the sheet for this date'
                      : 'Clear the search to see all vehicles',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                ),
                if (query.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      Get.find<DepotController>().filterDepotTrans('');
                    },
                    child: const Text('Clear search'),
                  ),
              ],
            ),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.only(top: 2, bottom: 12),
        itemCount: rows.length,
        itemBuilder: (context, index) => _buildVehicleCard(rows[index]),
      );
    });
  }

  Widget _buildVehicleCard(DepotFuel depotFuel) {
    final onRoute = depotFuel.On_route == true;
    return Card(
      elevation: depotFuel.dirty ? 2.5 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: depotFuel.dirty ? _warning : _outline,
          width: depotFuel.dirty ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVehicleHeader(depotFuel),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCrewInfo(depotFuel)),
                    const SizedBox(width: 10),
                    _buildOnRouteToggle(depotFuel),
                  ],
                ),
                // Defect and description only matter for vehicles that stay off
                // route; on-route vehicles hide them.
                if (!onRoute) ...[
                  const SizedBox(height: 10),
                  _buildDefectAndDescriptionFields(depotFuel),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleHeader(DepotFuel depotFuel) {
    final onRoute = depotFuel.On_route == true;
    final capacity = vehicle_type_desc.desc[depotFuel.Capacity];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryDark, _primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            onRoute ? Icons.check_circle : Icons.pause_circle_outline,
            size: 17,
            color: Colors.white70,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${depotFuel.Fleet ?? 'N/A'}  |  ${depotFuel.Vehicle ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (capacity != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                capacity,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (depotFuel.dirty) ...[
            const SizedBox(width: 6),
            const Icon(Icons.edit_note, size: 18, color: Colors.white),
          ],
        ],
      ),
    );
  }

  Widget _buildCrewInfo(DepotFuel depotFuel) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setvehicle(depotFuel.Vehicle ?? '', depotFuel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'CREW',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.bold,
                    color: _muted,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.edit, size: 13, color: _primary),
              ],
            ),
            const SizedBox(height: 6),
            _buildCrewMemberInfo(
                'Driver', depotFuel.Driver, depotFuel.Driver_Name),
            const SizedBox(height: 4),
            _buildCrewMemberInfo(
                'Conductor', depotFuel.Conductor, depotFuel.Conductor_Name),
          ],
        ),
      ),
    );
  }

  Widget _buildCrewMemberInfo(String role, String? id, String? name) {
    final hasInfo = !id.isNullOrEmpty;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: hasInfo ? const Color(0xFFE7F4EC) : const Color(0xFFFDECEC),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            role,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: hasInfo ? _success : _danger,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: hasInfo
              ? Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: id!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      if (!name.isNullOrEmpty)
                        TextSpan(
                          text: '  $name',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: _muted,
                          ),
                        ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              : Text(
                  'Not assigned',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _danger.withOpacity(0.8),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDefectAndDescriptionFields(DepotFuel depotFuel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDefectField(depotFuel),
        const SizedBox(height: 10),
        _buildDescriptionField(depotFuel),
      ],
    );
  }

  Widget _buildDefectField(DepotFuel depotFuel) {
    TextEditingController? internal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DEFECT (required when off route)',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 0.6,
            fontWeight: FontWeight.bold,
            color: _muted,
          ),
        ),
        const SizedBox(height: 4),
        TypeAheadField<Expenses>(
          suggestionsCallback: (pattern) async => suggestionsCallback(pattern),
          itemBuilder: (context, Expenses nro) => ListTile(
            dense: true,
            title: Text(nro.Code.toString()),
            subtitle: Text(nro.Description.toString()),
          ),
          onSelected: (Expenses nro) {
            depotFuel.Nro_Defects = nro.Code;
            depotFuel.Nro_Defects_editor.text = nro.Code.toString();
            _markDirty(depotFuel);
            // flutter_typeahead does not update its own controller on pick,
            // so set it explicitly to show the chosen defect.
            internal?.text = nro.Code.toString();
          },
          builder: (context, controller, focusNode) {
            internal = controller;
            // Prefill the typeahead's own controller if the editor has a value,
            // so previously picked defects still show after rebuilds.
            if (controller.text.isEmpty &&
                depotFuel.Nro_Defects_editor.text.isNotEmpty) {
              controller.text = depotFuel.Nro_Defects_editor.text;
            }
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                hintText: 'Search a defect code',
                hintStyle: const TextStyle(fontSize: 12.5),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _outline),
                ),
              ),
              onChanged: (value) {
                depotFuel.Nro_Defects = value;
                depotFuel.Nro_Defects_editor.text = value;
                _markDirty(depotFuel);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField(DepotFuel depotFuel) {
    return TextField(
      controller: depotFuel.desc_editor,
      style: const TextStyle(fontSize: 13),
      maxLines: 2,
      minLines: 1,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        hintText: 'Description / comment (optional)',
        hintStyle: const TextStyle(fontSize: 12.5),
        prefixIcon: const Icon(Icons.notes, size: 16, color: _muted),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _outline),
        ),
      ),
      onChanged: (value) {
        depotFuel.onDescriptionChanged(value);
        _markDirty(depotFuel);
      },
    );
  }

  /// Big, obvious on-route control that does not overflow on small phones.
  Widget _buildOnRouteToggle(DepotFuel depotFuel) {
    final onRoute = depotFuel.On_route == true;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _toggleOnRoute(depotFuel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: onRoute ? const Color(0xFFE7F4EC) : _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: onRoute ? _success : _outline,
            width: onRoute ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              onRoute ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 22,
              color: onRoute ? _success : _muted,
            ),
            const SizedBox(height: 2),
            Text(
              onRoute ? 'On route' : 'Off route',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: onRoute ? _success : _muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleOnRoute(DepotFuel depotFuel) {
    // toggle() flips On_route, flags the row dirty and refreshes the switch.
    Get.find<VehiclesController>().toggle(depotFuel);
    if (depotFuel.On_route == true) {
      depotFuel.From ??= getdatetime();
    }
    _markDirty(depotFuel);
  }

  /// Marks [depotFuel] as edited and refreshes the card frame once.
  void _markDirty(DepotFuel depotFuel) {
    final wasDirty = depotFuel.dirty;
    depotFuel.dirty = true;
    Get.find<DepotController>().refreshDirty();
    if (!wasDirty && mounted) setState(() {});
  }

  /// Transient feedback for this screen.
  ///
  /// Uses the ScaffoldMessenger instead of `Get.snackbar`: GetX resolves an
  /// Overlay through the current route and can throw "No Overlay widget found"
  /// mid-rebuild, which previously aborted [update] *after* the rows had
  /// already been saved - so a successful save looked like a failure.
  void _notify(String message, {Color? background}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: background,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    // Fall back to GetX when there is no ScaffoldMessenger yet.
    try {
      Get.snackbar(
        'Dispatch',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: background,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (_) {
      debugPrint('[DISPATCH] toast failed: $message');
    }
  }

  Future<void> update() async {
    final ctrl = Get.find<DepotController>();
    // Save the whole sheet - an active search must never hide pending rows.
    final depots = ctrl.allDepots;
    final dirty = depots.where((d) => d.dirty).toList();

    if (dirty.isEmpty) {
      _notify('Nothing to save - change a vehicle first');
      return;
    }

    // Enforce: every modified vehicle must be on route OR carry a defect code.
    final invalid = dirty
        .where((d) =>
            d.On_route != true &&
            (d.Nro_Defects == null || d.Nro_Defects!.trim().isEmpty))
        .toList();

    if (invalid.isNotEmpty) {
      final vehicles = invalid.map((d) => d.Vehicle ?? '?').take(5).join(', ');
      _notify(
        'Tick "On route" or pick a defect for: $vehicles'
        '${invalid.length > 5 ? ' (+${invalid.length - 5} more)' : ''}',
        background: _danger,
      );
      return;
    }

    final saved = await DepotFuel().updatedepot(depots);
    if (!mounted) return;
    setState(() {});
    ctrl.refreshDirty();
    if (saved) {
      _notify(
        'Saved - dispatch updated for ${dirty.length} '
        'vehicle${dirty.length == 1 ? '' : 's'}',
        background: _success,
      );
    }
  }

  /// Sticky bar showing pending edits and the save action.
  Widget _buildSaveBar(DepotController dp) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _outline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Obx(() {
                final pending = dp.dirtyCount.value;
                final total = dp.depottrans1.isNotEmpty
                    ? dp.depottrans1.length
                    : dp.depottrans.length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pending == 0
                          ? 'All changes saved'
                          : '$pending of $total to save',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: pending == 0 ? _success : _ink,
                      ),
                    ),
                    Text(
                      pending == 0
                          ? 'No pending edits'
                          : 'Tap save to send to Business Central',
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(width: 10),
            Obx(() {
              final isUpdating = dp.updating.value;
              final progress = dp.updateProgress.value;
              final total = dp.updateTotal.value;
              final pending = dp.dirtyCount.value;
              return FilledButton.icon(
                onPressed: (isUpdating || pending == 0) ? null : update,
                icon: isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text(
                  isUpdating
                      ? (total > 0 ? 'Saving $progress/$total' : 'Saving...')
                      : 'Save',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryDark,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> setvehicle(String vehicle, DepotFuel depotFuel) async {
    Vehicles? veh;
    try {
      // Use the shared controller - constructing VehiclesController() here
      // reloaded every vehicle from the database on each tap.
      veh = await Get.find<VehiclesController>().getcurrvehicle(vehicle);
    } catch (e) {
      // getcurrvehicle also refreshes the transaction types; never let that
      // stop the crew screen from opening.
      debugPrint('[DISPATCH] getcurrvehicle($vehicle) failed: $e');
    }
    if (veh == null) {
      _notify('Vehicle $vehicle was not found on this device',
          background: _danger);
      return;
    }

    final result = await Get.to<Vehicles>(
      () => CrewAssignment(
        vehicle: veh,
        driverNo: depotFuel.Driver,
        conductorNo: depotFuel.Conductor,
      ),
    );
    if (!mounted) return;

    Member? driver;
    Member? conductor;
    if (result != null) {
      driver = result.Driver;
      conductor = result.Conductor;
    } else {
      // No result came back (a plain pop) - read what the crew screen stored.
      final members = Get.find<MemberController>().allMembers;
      if (members.isEmpty) return;
      for (final m in members) {
        if (m.Vehicle != vehicle) continue;
        if (m.Crew_Type == Crew_type.Driver) driver = m;
        if (m.Crew_Type == Crew_type.Conductor) conductor = m;
      }
    }

    final newDriver = driver?.No;
    final newDriverName = driver?.Name;
    final newConductor = conductor?.No;
    final newConductorName = conductor?.Name;

    final changed = depotFuel.Driver != newDriver ||
        depotFuel.Driver_Name != newDriverName ||
        depotFuel.Conductor != newConductor ||
        depotFuel.Conductor_Name != newConductorName;

    depotFuel.Driver = newDriver;
    depotFuel.Driver_Name = newDriverName;
    depotFuel.Conductor = newConductor;
    depotFuel.Conductor_Name = newConductorName;

    if (changed) {
      _markDirty(depotFuel);
    } else if (mounted) {
      setState(() {}); // refresh the card even when nothing changed
    }
  }

  Future<List<Expenses>> suggestionsCallback(String pattern) async {
    return Get.find<VehiclesController>().NRODefects.where((product) {
      final nameLower = product.toString().toLowerCase();
      return nameLower.contains(pattern.toLowerCase());
    }).toList();
  }
}

class LabeledCheckbox extends StatelessWidget {
  const LabeledCheckbox({
    Key? key,
    required this.label,
    required this.padding,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final String label;
  final EdgeInsets padding;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged(!value);
      },
      child: Padding(
        padding: padding,
        child: Row(
          children: <Widget>[
            Checkbox(
              value: value,
              onChanged: (bool? newValue) {
                onChanged(newValue ?? false);
              },
            ),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
