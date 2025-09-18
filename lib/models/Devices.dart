import 'dart:convert';



// ignore_for_file: public_member_api_docs, sort_constructors_first
class Devices {
  String? Key;
  String? Device_id;
  String? Manufacturer;
  String? Brand;
  Devices({
    this.Key,
    this.Device_id,
    this.Manufacturer,
    this.Brand,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Key': Key,
      'Device_id': Device_id,
      'Manufacturer': Manufacturer,
      'Brand': Brand,
    };
  }

  factory Devices.fromMap(Map<String, dynamic> map) {
    return Devices(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Device_id: map['Device_id'] != null ? map['Device_id'] as String : null,
      Manufacturer:
          map['Manufacturer'] != null ? map['Manufacturer'] as String : null,
      Brand: map['Brand'] != null ? map['Brand'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Devices.fromJson(String source) =>
      Devices.fromMap(json.decode(source) as Map<String, dynamic>);
}
