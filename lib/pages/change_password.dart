import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/agent.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/models/agents.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/utils/snackbar_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final RxBool _isLoading = false.obs;
  final RxBool _obscureCurrentPassword = true.obs;
  final RxBool _obscureNewPassword = true.obs;
  final RxBool _obscureConfirmPassword = true.obs;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate passwords match
    if (newPassword != confirmPassword) {
      SnackbarService.showError('New passwords do not match');
      return;
    }

    // Validate new password is different from current
    if (currentPassword == newPassword) {
      SnackbarService.showError(
          'New password must be different from current password');
      return;
    }

    _isLoading.value = true;

    try {
      final mainController = Get.find<MainController>();
      final agent = mainController.agent.value;

      // Check if agent is properly logged in
      if (agent.Agent_Code == null || agent.Agent_Code!.isEmpty) {
        SnackbarService.showError('No user logged in');
        return;
      }

      // Verify current password
      final storedPassword = AgentController().decrypt(agent.Password ?? '');
      if (storedPassword != currentPassword) {
        SnackbarService.showError('Current password is incorrect');
        return;
      }

      // Update agent password and send full agent object
      agent.Password = newPassword;

      final response = await ApiClient().postdata(
        'changepassword',
        agent.toJson(),
      );

      if (response.statusCode == 200) {
        // Password updated on server - refresh agents to get new encrypted password
        await Agent().getagents();

        SnackbarService.showSuccess('Password changed successfully');

        // Clear fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        // Go back
        Get.back();
      } else {
        final errorBody = response.body;
        SnackbarService.showError('Failed to change password: $errorBody');
      }
    } catch (e) {
      SnackbarService.showError('Error: ${e.toString()}');
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Current user info
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue, size: 40),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Get.find<MainController>().agent.value.Name ??
                                  'Unknown',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              Get.find<MainController>()
                                      .agent
                                      .value
                                      .Agent_Code ??
                                  '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Current Password
                Obx(() => TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrentPassword.value,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrentPassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => _obscureCurrentPassword.value =
                              !_obscureCurrentPassword.value,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your current password';
                        }
                        return null;
                      },
                    )),
                const SizedBox(height: 20),

                // New Password
                Obx(() => TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword.value,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => _obscureNewPassword.value =
                              !_obscureNewPassword.value,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a new password';
                        }
                        if (value.length < 4) {
                          return 'Password must be at least 4 characters';
                        }
                        return null;
                      },
                    )),
                const SizedBox(height: 20),

                // Confirm Password
                Obx(() => TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword.value,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: const Icon(Icons.lock_clock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => _obscureConfirmPassword.value =
                              !_obscureConfirmPassword.value,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    )),
                const SizedBox(height: 30),

                // Change Password Button
                Obx(() => _isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _changePassword,
                        icon: const Icon(Icons.security),
                        label: const Text(
                          'Change Password',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )),
                const SizedBox(height: 20),

                // Password requirements hint
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Password Requirements',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Minimum 4 characters',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                        Text(
                          '• Must be different from current password',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
