import 'package:flutter/material.dart';

class ShimmerLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (_, __) => Card(
        margin: EdgeInsets.all(8),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[200]!, Colors.grey[100]!, Colors.grey[200]!],
              stops: [0.1, 0.3, 0.4],
              begin: Alignment(-1.0, -0.3),
              end: Alignment(1.0, 0.3),
            ),
          ),
        ),
      ),
    );
  }
}
