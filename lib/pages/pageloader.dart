import 'package:flutter/material.dart';



class PageLoader extends StatelessWidget {
  const PageLoader({super.key, required this.page, required this.title});
final Widget page;
final String title;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        elevation: 4,
        centerTitle: true,
        toolbarHeight: 40,
      ),
      body: page,
    );
  }
}
