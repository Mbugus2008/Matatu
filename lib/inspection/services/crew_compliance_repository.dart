import 'dart:io';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/crew_compliance_entry.dart';

class CrewComplianceRepository extends GetxService {
  static const String boxName = 'crew_compliance_entries';

  late Box<CrewComplianceEntry> _box;
  late Directory _storageDirectory;

  Future<CrewComplianceRepository> init() async {
    _box = await Hive.openBox<CrewComplianceEntry>(boxName);
    final Directory documentsDir = await getApplicationDocumentsDirectory();
    _storageDirectory =
        Directory(p.join(documentsDir.path, 'crew_compliance', 'documents'));
    if (!await _storageDirectory.exists()) {
      await _storageDirectory.create(recursive: true);
    }
    return this;
  }

  Future<String> persistAttachment(File source) async {
    if (!await source.exists()) {
      throw Exception('Attachment does not exist at ${source.path}');
    }
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(source.path)}';
    final File target = File(p.join(_storageDirectory.path, fileName));
    return (await source.copy(target.path)).path;
  }

  Future<CrewComplianceEntry> saveEntry(CrewComplianceEntry entry) async {
    await _box.put(entry.id, entry);
    return entry;
  }

  List<CrewComplianceEntry> getAllEntries() {
    return _box.values.toList(growable: false);
  }

  List<CrewComplianceEntry> getPendingEntries() {
    return _box.values
        .where((CrewComplianceEntry entry) => !entry.isSynced)
        .toList(growable: false);
  }

  Future<void> markSynced(String id) async {
    final CrewComplianceEntry? entry = _box.get(id);
    if (entry == null) {
      return;
    }
    await _box.put(
        id, entry.copyWith(isSynced: true, updatedAt: DateTime.now()));
  }

  Future<void> removeEntry(String id) async {
    await _box.delete(id);
  }
}
