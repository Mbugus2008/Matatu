import 'dart:convert';

class InspectionItemData {
  InspectionItemData({
    required this.key,
    required this.label,
    this.isCompliant = true,
    this.rating = 'Good',
    this.notes = '',
    List<String>? photoPaths,
  }) : photoPaths = photoPaths ?? <String>[];

  final String key;
  final String label;
  bool isCompliant;
  String rating;
  String notes;
  final List<String> photoPaths;

  InspectionItemData copyWith({
    bool? isCompliant,
    String? rating,
    String? notes,
    List<String>? photoPaths,
  }) {
    return InspectionItemData(
      key: key,
      label: label,
      isCompliant: isCompliant ?? this.isCompliant,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      photoPaths: photoPaths ?? List<String>.from(this.photoPaths),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'key': key,
      'label': label,
      'isCompliant': isCompliant,
      'rating': rating,
      'notes': notes,
      'photoPaths': photoPaths,
    };
  }

  factory InspectionItemData.fromJson(Map<String, dynamic> json) {
    return InspectionItemData(
      key: json['key'] as String,
      label: json['label'] as String? ?? json['key'] as String,
      isCompliant: json['isCompliant'] as bool? ?? true,
      rating: json['rating'] as String? ?? 'Good',
      notes: json['notes'] as String? ?? '',
      photoPaths:
          (json['photoPaths'] as List<dynamic>?)
              ?.map((dynamic value) => value.toString())
              .toList() ??
          <String>[],
    );
  }
}

class BusInspection {
  const BusInspection({
    this.id,
    required this.busIdentifier,
    this.inspectorName,
    required this.inspectionDate,
    required this.items,
    this.isSynced = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? inspectionDate,
       updatedAt = updatedAt ?? inspectionDate;

  final int? id;
  final String busIdentifier;
  final String? inspectorName;
  final DateTime inspectionDate;
  final Map<String, InspectionItemData> items;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusInspection copyWith({
    int? id,
    String? busIdentifier,
    String? inspectorName,
    DateTime? inspectionDate,
    Map<String, InspectionItemData>? items,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusInspection(
      id: id ?? this.id,
      busIdentifier: busIdentifier ?? this.busIdentifier,
      inspectorName: inspectorName ?? this.inspectorName,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      items: items ?? Map<String, InspectionItemData>.from(this.items),
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'busIdentifier': busIdentifier,
      'inspectorName': inspectorName,
      'inspectionDate': inspectionDate.toIso8601String(),
      'items': items.map<String, dynamic>((
        String key,
        InspectionItemData value,
      ) {
        return MapEntry<String, dynamic>(key, value.toJson());
      }),
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BusInspection.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> itemMap =
        json['items'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return BusInspection(
      id: json['id'] as int?,
      busIdentifier: json['busIdentifier'] as String,
      inspectorName: json['inspectorName'] as String?,
      inspectionDate: DateTime.parse(json['inspectionDate'] as String),
      items: itemMap.map<String, InspectionItemData>((
        String key,
        dynamic value,
      ) {
        return MapEntry<String, InspectionItemData>(
          key,
          InspectionItemData.fromJson(value as Map<String, dynamic>),
        );
      }),
      isSynced: json['isSynced'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toDbMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'bus_identifier': busIdentifier,
      'inspector_name': inspectorName,
      'inspection_date': inspectionDate.toIso8601String(),
      'fields_json': jsonEncode(
        items.map<String, dynamic>((String key, InspectionItemData value) {
          return MapEntry<String, dynamic>(key, value.toJson());
        }),
      ),
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BusInspection.fromDbMap(Map<String, dynamic> map) {
    final String rawItems = map['fields_json'] as String? ?? '{}';
    final Map<String, dynamic> decoded =
        rawItems.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(rawItems) as Map<String, dynamic>;
    return BusInspection(
      id: map['id'] as int?,
      busIdentifier: map['bus_identifier'] as String,
      inspectorName: map['inspector_name'] as String?,
      inspectionDate: DateTime.parse(map['inspection_date'] as String),
      items: decoded.map<String, InspectionItemData>((
        String key,
        dynamic value,
      ) {
        return MapEntry<String, InspectionItemData>(
          key,
          InspectionItemData.fromJson(value as Map<String, dynamic>),
        );
      }),
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
