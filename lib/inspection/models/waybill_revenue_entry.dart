import 'package:hive/hive.dart';

class WaybillRevenueEntry {
  WaybillRevenueEntry({
    required this.id,
    required this.vehicleCode,
    required this.vehicleNumber,
    required this.date,
    required this.targetRevenue,
    required this.actualRevenue,
    required this.offloadPerTrip,
    required this.waybillEndorsed,
    required this.feesPaid,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  final String id;
  final String vehicleCode;
  final String vehicleNumber;
  final DateTime date;
  final double targetRevenue;
  final double actualRevenue;
  final double offloadPerTrip;
  final bool waybillEndorsed;
  final bool feesPaid;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  WaybillRevenueEntry copyWith({
    double? targetRevenue,
    double? actualRevenue,
    double? offloadPerTrip,
    bool? waybillEndorsed,
    bool? feesPaid,
    String? notes,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return WaybillRevenueEntry(
      id: id,
      vehicleCode: vehicleCode,
      vehicleNumber: vehicleNumber,
      date: date,
      targetRevenue: targetRevenue ?? this.targetRevenue,
      actualRevenue: actualRevenue ?? this.actualRevenue,
      offloadPerTrip: offloadPerTrip ?? this.offloadPerTrip,
      waybillEndorsed: waybillEndorsed ?? this.waybillEndorsed,
      feesPaid: feesPaid ?? this.feesPaid,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toApiPayload() {
    return <String, dynamic>{
      'id': id,
      'vehicleCode': vehicleCode,
      'vehicleNumber': vehicleNumber,
      'date': date.toIso8601String(),
      'targetRevenue': targetRevenue,
      'actualRevenue': actualRevenue,
      'offloadPerTrip': offloadPerTrip,
      'waybillEndorsed': waybillEndorsed,
      'feesPaid': feesPaid,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class WaybillRevenueEntryAdapter extends TypeAdapter<WaybillRevenueEntry> {
  @override
  final int typeId = 12;

  @override
  WaybillRevenueEntry read(BinaryReader reader) {
    final int numOfFields = reader.readByte();
    final Map<int, dynamic> fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return WaybillRevenueEntry(
      id: fields[0] as String,
      vehicleCode: fields[1] as String,
      vehicleNumber: fields[2] as String,
      date: DateTime.parse(fields[3] as String),
      targetRevenue: (fields[4] as num).toDouble(),
      actualRevenue: (fields[5] as num).toDouble(),
      offloadPerTrip: (fields[6] as num).toDouble(),
      waybillEndorsed: fields[7] as bool,
      feesPaid: fields[8] as bool,
      notes: fields[9] as String?,
      createdAt: DateTime.parse(fields[10] as String),
      updatedAt: DateTime.parse(fields[11] as String),
      isSynced: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WaybillRevenueEntry obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleCode)
      ..writeByte(2)
      ..write(obj.vehicleNumber)
      ..writeByte(3)
      ..write(obj.date.toIso8601String())
      ..writeByte(4)
      ..write(obj.targetRevenue)
      ..writeByte(5)
      ..write(obj.actualRevenue)
      ..writeByte(6)
      ..write(obj.offloadPerTrip)
      ..writeByte(7)
      ..write(obj.waybillEndorsed)
      ..writeByte(8)
      ..write(obj.feesPaid)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.createdAt.toIso8601String())
      ..writeByte(11)
      ..write(obj.updatedAt.toIso8601String())
      ..writeByte(12)
      ..write(obj.isSynced);
  }
}
