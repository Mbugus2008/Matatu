import 'package:flutter/material.dart';
import 'package:t_matatu/models/Reversal.dart';

class ReversalFormScreen extends StatefulWidget {
  final Reversal? reversal;

  ReversalFormScreen({this.reversal});

  @override
  _ReversalFormScreenState createState() => _ReversalFormScreenState();
}

class _ReversalFormScreenState extends State<ReversalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Reversal _reversal;

  @override
  void initState() {
    super.initState();
    _reversal = widget.reversal ?? Reversal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reversal == null ? 'Add Reversal' : 'Edit Reversal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _reversal.No,
                decoration: InputDecoration(labelText: 'No'),
                onSaved: (value) {
                  _reversal.No = value;
                },
              ),
              TextFormField(
                initialValue: _reversal.Receipt_No,
                decoration: InputDecoration(labelText: 'Receipt No'),
                onSaved: (value) {
                  _reversal.Receipt_No = value;
                },
              ),
              // Add more form fields for the other properties
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Save reversal data
                    Navigator.of(context).pop(_reversal);
                  }
                },
                child: Text(widget.reversal == null ? 'Add' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
