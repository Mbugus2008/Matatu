import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/main.dart';

class PageLoader extends StatelessWidget {
  const PageLoader({
    super.key,
    required this.page,
    required this.title,
    this.actions,
  });

  final Widget page;
  final String title;
  final List<Widget>? actions;

  Color _primaryColor() {
    final hex = Get.find<MainController>()
        .config?.value.theme?.primaryColor;
    if (hex == null) return Colors.blue;
    final clean = hex.replaceFirst('#', '');
    final full = clean.length == 6 ? 'FF$clean' : clean;
    return Color(int.parse(full, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _primaryColor();
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        elevation: 4,
        centerTitle: true,
        toolbarHeight: 40,
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: actions,
      ),
      body: page,
    );
  }
}
