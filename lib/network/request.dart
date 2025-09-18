// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:t_matatu/models/Utils/util.dart';

class Request {
  String? body;
  String? Otp;
  String? phone;
  String? Otp_message;
  String? bookmark;
  String? vehicle;
  DateTime? date;
  int? size;
  String? Agent;
  Request({
    this.Agent,
    this.body,
    this.Otp = '',
    this.phone = '',
    this.Otp_message = '',
    this.bookmark,
    this.vehicle,
    this.date,
    this.size =0,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'body': body,
      'Agent': Agent,
      'Otp': Otp,
      'phone': phone,
      'Otp_message': Otp_message,
      'bookmark': bookmark,
      'vehicle': vehicle,
      'date': date == null ? null : formattedDate.format(date!),
      'size': size,
    };
  }

  factory Request.fromMap(Map<String, dynamic> map) {
    return Request(
      body: map['body'] != null ? map['body'] as String : null,
      Agent: map['Agent'] != null ? map['Agent'] as String : null,
      Otp: map['Otp'] != null ? map['Otp'] as String : null,
      phone: map['phone'] != null ? map['phone'] as String : null,
      Otp_message:
          map['Otp_message'] != null ? map['Otp_message'] as String : null,
      bookmark: map['bookmark'] != null ? map['bookmark'] as String : null,
      vehicle: map['vehicle'] != null ? map['vehicle'] as String : null,
      date: map['date'] != null
          ? DateFormat("dd/MM/yyyy").parse((map['date'] ?? 0))
          : null,
      size: map['size'] != null ? map['size'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Request.fromJson(String source) =>
      Request.fromMap(json.decode(source) as Map<String, dynamic>);
}

class RequestHeader {
  String? userid;
  String? password;
  RequestHeader({
    this.userid = '',
    this.password = '',
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userid': userid,
      'password': password,
    };
  }

  factory RequestHeader.fromMap(Map<String, dynamic> map) {
    return RequestHeader(
      userid: map['userid'] != null ? map['userid'] as String : null,
      password: map['password'] != null ? map['password'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory RequestHeader.fromJson(String source) =>
      RequestHeader.fromMap(json.decode(source) as Map<String, dynamic>);
}
