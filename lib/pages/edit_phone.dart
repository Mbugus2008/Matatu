import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/Members.dart';
import 'package:t_matatu/models/member.dart';
import 'package:t_matatu/providers/db.dart';

class EditPhonePage extends StatefulWidget {
  const EditPhonePage({Key? key, required this.member}) : super(key: key);
  
   final Member member;

  @override
  _EditPhonePageState createState() => _EditPhonePageState();
}

class _EditPhonePageState extends State<EditPhonePage> {
  final _formKey = GlobalKey<FormState>();
  late final Member member;
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    member = widget.member;
    _phoneController.text = member.Phone_No ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updatePhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update the member's phone number
      member.Phone_No = _phoneController.text.trim();
      
      // Update in the database
      await Get.find<db_Provider>().updatedata(
        Member.table,
        {'Phone_No': member.Phone_No},
        'No = ?',
        [member.No!],
      );

      // Update in the controller's lists
      final memberController = Get.find<MemberController>();
      
      // Update in allMembers list
      final allIndex = memberController.allMembers.indexWhere((m) => m.No == member.No);
      if (allIndex != -1) {
        memberController.allMembers[allIndex].Phone_No = member.Phone_No;
      }
      
      // Update in Crews list if it exists there
      final crewIndex = memberController.Crews.indexWhere((m) => m.No == member.No);
      if (crewIndex != -1) {
        memberController.Crews[crewIndex].Phone_No = member.Phone_No;
      }
      
      // Update in Memberss list if it exists there
      final memberIndex = memberController.Memberss.indexWhere((m) => m.No == member.No);
      if (memberIndex != -1) {
        memberController.Memberss[memberIndex].Phone_No = member.Phone_No;
      }
      memberController.updatephone(member);
      // Update the UI
      memberController.update();
      
      Get.back(result: true); // Return success
      Get.snackbar('Success', 'Phone number updated successfully',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update phone number: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Phone Number'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updatePhone,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Member: ${member.Name} (${member.No})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updatePhone,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
