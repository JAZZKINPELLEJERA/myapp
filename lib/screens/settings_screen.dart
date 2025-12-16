import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tindahance/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final _storeNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (_currentUser != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _storeNameController.text = doc.data()!['storeName'];
          _ownerNameController.text = doc.data()!['ownerName'];
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_currentUser == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).update({
        'storeName': _storeNameController.text,
        'ownerName': _ownerNameController.text,
      });

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Changes saved successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error saving changes: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.teal[400]),
            const SizedBox(width: 10),
            Text('About TINDAHANCE', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TINDAHANCE is a mobile Point-of-Sale (POS) application developed to assist sari-sari store owners in managing sales transactions, inventory, and business records.',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 15),
              Text(
                'The application aims to improve accuracy, efficiency, and convenience in small-scale retail operations through the use of modern mobile technology.',
                 style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              Text('Developer:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 5),
              Text('JAZZKIN C. PELLEJERA', style: GoogleFonts.poppins(fontSize: 14)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.teal[400])),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmNewPasswordController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Text('Change Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          errorMessage!,
                          style: GoogleFonts.poppins(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    _buildPasswordTextField(
                      controller: currentPasswordController,
                      labelText: 'Current Password',
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordTextField(
                      controller: newPasswordController,
                      labelText: 'New Password',
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter a new password';
                        if (value.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordTextField(
                      controller: confirmNewPasswordController,
                      labelText: 'Re-enter New Password',
                      validator: (value) {
                        if (value != newPasswordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.teal[400])),
                ),
                ElevatedButton(
                   style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      try {
                        await _authService.changePassword(
                          currentPasswordController.text,
                          newPasswordController.text,
                        );
                        navigator.pop();
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Colors.green),
                        );
                      } on FirebaseAuthException catch (e) {
                        setDialogState(() {
                          if (e.code == 'wrong-password') {
                            errorMessage = 'Incorrect current password.';
                          } else {
                            errorMessage = 'An error occurred. Please try again.';
                          }
                        });
                      } catch (e) {
                         setDialogState(() {
                            errorMessage = 'An unexpected error occurred.';
                        });
                      }
                    }
                  },
                  child: Text('Save Changes', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Delete Account', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('This action is irreversible and will permanently delete your account. Are you sure?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.teal[400])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
               shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onPressed: () async {
              try {
                await _authService.deleteAccount();
                navigator.popUntil((route) => route.isFirst);
              } catch (e) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error deleting account: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildEditProfileSection(),
          const SizedBox(height: 20),
          const Divider(thickness: 1),
          const SizedBox(height: 10),
          _buildSettingsOptionsList(),
        ],
      ),
    );
  }

  Widget _buildEditProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _buildProfileTextField(
          controller: _storeNameController,
          labelText: 'Store Name',
          icon: Icons.store,
        ),
        const SizedBox(height: 16),
        _buildProfileTextField(
          controller: _ownerNameController,
          labelText: 'Owner Name',
          icon: Icons.person,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1ABC9C),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          child: Text(
            'Save Changes',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
  }) {
     return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.poppins(),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFF1ABC9C), width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.black, width: 1.0),
        ),
      ),
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
  }) {
    bool isVisible = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return TextFormField(
          controller: controller,
          obscureText: !isVisible,
          decoration: InputDecoration(
            labelText: labelText,
             labelStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
             focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFF1ABC9C), width: 2.0),
            ),
            suffixIcon: IconButton(
              icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => isVisible = !isVisible),
            ),
          ),
          validator: validator,
        );
      },
    );
  }


  Widget _buildSettingsOptionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App Settings',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildSettingsListItem(
          title: 'About',
          icon: Icons.info_outline,
          onTap: _showAboutDialog,
        ),
        _buildSettingsListItem(
          title: 'Change Password',
          icon: Icons.lock_outline,
          onTap: _showChangePasswordDialog,
        ),
        _buildSettingsListItem(
          title: 'Delete Account',
          icon: Icons.delete_outline,
          iconColor: Colors.red,
          textColor: Colors.red,
          onTap: _showDeleteAccountDialog,
        ),
      ],
    );
  }

  Widget _buildSettingsListItem({
    required String title,
    required IconData icon,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    bool isDelete = title == 'Delete Account';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        leading: CircleAvatar(
          backgroundColor: isDelete ? Colors.red.withOpacity(0.1) : Colors.teal.withOpacity(0.1),
          child: Icon(icon, color: iconColor ?? (isDelete ? Colors.red : Colors.teal[400])),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor ?? Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }
}
