import 'package:flutter/material.dart';
import 'package:t_matatu/pages/Depot.dart';
import 'package:t_matatu/pages/Fuel.dart';

class TwoTabScreen extends StatefulWidget {
  const TwoTabScreen({Key? key}) : super(key: key);

  @override
  _TwoTabScreenState createState() => _TwoTabScreenState();
}

class _TwoTabScreenState extends State<TwoTabScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: const Text('Operations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Depot'),
            Tab(text: 'Fuel'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          Depot(),
          Fuel(),
        ],
      ),
    );
  }
} 