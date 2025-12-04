import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';

class CrewComplianceEntry {
  CrewComplianceEntry({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.documentPaths,
    this.grooming,
    this.behavior,
    this.notes = '',
    this.isSynced = false,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, String> documentPaths;
  final String? grooming;
  final String? behavior;
  final String notes;
  final bool isSynced;

  CrewComplianceEntry copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, String>? documentPaths,
    String? grooming,
    String? behavior,
    String? notes,
    bool? isSynced,
  }) {
    return CrewComplianceEntry(
      id: id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      documentPaths:
          documentPaths ?? Map<String, String>.from(this.documentPaths),
      grooming: grooming ?? this.grooming,
      behavior: behavior ?? this.behavior,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson({bool includeDocuments = true}) {
    return <String, dynamic>{
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'grooming': grooming,
      'behavior': behavior,
      'notes': notes,
      'documents': includeDocuments ? documentPaths : null,
      'isSynced': isSynced,
    };
  }

  Map<String, dynamic> toApiPayload() {
    final Map<String, dynamic> payload = toJson(includeDocuments: false);
    payload['documents'] = documentPaths.map(
      (String key, String path) {
        final File file = File(path);
        if (!file.existsSync()) {
          return MapEntry<String, dynamic>(key, null);
        }
        final List<int> bytes = file.readAsBytesSync();
        final String fileName = path.split(Platform.pathSeparator).last;
        return MapEntry<String, dynamic>(key, <String, dynamic>{
          'fileName': fileName,
          'base64': base64Encode(bytes),
        });
      },
    );
    return payload;
  }
}

class CrewComplianceEntryAdapter extends TypeAdapter<CrewComplianceEntry> {
  @override
  final int typeId = 11;

  @override
  CrewComplianceEntry read(BinaryReader reader) {
    final int numOfFields = reader.readByte();
    final Map<int, dynamic> fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return CrewComplianceEntry(
      id: fields[0] as String,
      createdAt: DateTime.parse(fields[1] as String),
      updatedAt: DateTime.parse(fields[2] as String),
      documentPaths: Map<String, String>.from(fields[3] as Map),
      grooming: fields[4] as String?,
      behavior: fields[5] as String?,
      notes: fields[6] as String? ?? '',
      isSynced: fields[7] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CrewComplianceEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt.toIso8601String())
      ..writeByte(2)
      ..write(obj.updatedAt.toIso8601String())
      ..writeByte(3)
      ..write(obj.documentPaths)
      ..writeByte(4)
      ..write(obj.grooming)
      ..writeByte(5)
      ..write(obj.behavior)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.isSynced);
  }
}

class CrewComplianceDocumentKeys {
  static const String insurance = 'insurance';
  static const String psvLicense = 'psvLicense';
  static const String ntsaCompliance = 'ntsaCompliance';
  static const String uniforms = 'uniforms';

  static const List<String> ordered = <String>[
    insurance,
    psvLicense,
    ntsaCompliance,
    uniforms,
  ];

  static String label(String key) {
    switch (key) {
      case insurance:
        return 'Insurance';
      case psvLicense:
        return 'PSV License';
      case ntsaCompliance:
        return 'NTSA Compliance';
      case uniforms:
        return 'Uniforms';
      default:
        return key;
    }
  }
}

class ComplianceDocument {
  ComplianceDocument({required this.path, required this.name});

  final String path;
  final String name;
}
