// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/providers/client.dart';
import 'package:t_matatu/providers/clients/Citihoppa.dart';
import 'package:t_matatu/providers/clients/Kmos.dart';
import 'package:t_matatu/providers/clients/Lopha.dart';

class ThemeConfig {
  String primaryColor;
  String accentColor;

  ThemeConfig({required this.primaryColor, required this.accentColor});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'primaryColor': primaryColor,
      'accentColor': accentColor,
    };
  }

  factory ThemeConfig.fromMap(Map<String, dynamic> map) {
    return ThemeConfig(
      primaryColor: (map['primaryColor'] ?? '') as String,
      accentColor: (map['accentColor'] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ThemeConfig.fromJson(String source) =>
      ThemeConfig.fromMap(json.decode(source) as Map<String, dynamic>);
}

class AppConfig {
  String? apiBaseUrl;
  String? updateUrl;
  String? clientId;
  String? clientName;
  String? logo;
  ThemeConfig? theme;
  String? email;
  String? telephone;
  String? street;
  String? address;
  String? city;
  String? Box;
  BaseClients? Client;

  AppConfig({
    this.apiBaseUrl,
    this.updateUrl,
    this.clientId,
    this.clientName,
    this.logo,
    this.theme,
    this.Client,
  });

init(AppConfig app){Get .find<MainController>().CurrentClient  ?.value = app.Client!;}

   

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'apiBaseUrl': apiBaseUrl,
      'updateUrl': updateUrl,
      'clientId': clientId,
      'clientName': clientName,
      'logo': logo,
      'theme': theme?.toMap(),
    };
  }

  String toJson() => json.encode(toMap());
  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      apiBaseUrl:
          map['apiBaseUrl'] != null ? map['apiBaseUrl'] as String : null,
      updateUrl: map['updateUrl'] != null ? map['updateUrl'] as String : null,
      clientId: map['clientId'] != null ? map['clientId'] as String : null,
      clientName:
          map['clientName'] != null ? map['clientName'] as String : null,
      logo: map['logo'] != null ? map['logo'] as String : null,
      theme: map['theme'] != null
          ? ThemeConfig.fromMap(map['theme'] as Map<String, dynamic>)
          : null,
          Client: map['Client'] != null
          ? BaseClients.fromMap(map['Client'] as Map<String, dynamic>)
          : null,
    );
  }
  factory AppConfig.fromJson(String source) =>
      AppConfig.fromMap(json.decode(source) as Map<String, dynamic>);
}
