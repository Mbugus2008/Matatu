// ignore_for_file: non_constant_identifier_names, camel_case_types

abstract class mapping<T> {
  T toMap_fortable();
}

abstract class Tomaps<T> {
  Map<String, dynamic> toMap();
  T fromMap_table(Map<String, dynamic> map);
}

abstract class data<T> {
  Future<List<T>> getall();
}
