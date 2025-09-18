import 'package:intl/intl.dart';
import 'package:t_matatu/models/Utils/util.dart';
import 'package:t_matatu/models/mappings.dart';

class Settings  implements Tomaps {
 DateTime? WorkingDate;
  Settings({
    this.WorkingDate,
  }); 

@override
Map<String, dynamic> toMap() {
  return {
    'WorkingDate': formattedDate.format(WorkingDate!),
  };
}

@override
Map<String, dynamic> toMap_table() {
  return {
    'WorkingDate': formattedDate.format(WorkingDate!),
  };
}


factory Settings.fromMap(Map<String, dynamic> map) {
  return Settings(
    WorkingDate: map['WorkingDate'] != null ? DateFormat("MM/dd/yyyy").parse((map['WorkingDate'] ?? 0)) : null,
  );
}

@override
Map<String, dynamic> fromMap_table(Map<String, dynamic> map) {
  return {
    'WorkingDate': map['WorkingDate'] != null ? map['WorkingDate'] as String : null,
  };
}

}