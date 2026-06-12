import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/patient_model.dart';
import 'caregiver_account_screen.dart';
import 'caregiver_dashboard_screen.dart';
import 'patient_dashboard_screen.dart';

enum LoginRole {
  caregiver,
  patient,
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginRole selectedRole = LoginRole.caregiver;

  final userIdController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    userIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() {
    final userId = userIdController.text.trim();
    final password = passwordController.text.trim();

    if (userId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ইউজার আইডি ও পাসওয়ার্ড দিন'),
        ),
      );
      return;
    }

    if (selectedRole == LoginRole.caregiver) {
      final isMatched = AppData.caregiverLoginMatched(
        userId: userId,
        password: password,
      );

      if (!isMatched) {
        showErrorDialog('পরিচর্যাকারীর তথ্য মেলেনি');
        return;
      }

      showLoginSuccessDialog(
        onOk: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CaregiverDashboardScreen(
                caregiverName: AppData.caregiver!.fullName,
              ),
            ),
          );
        },
      );
    } else {
      final Patient? patient = AppData.findPatientByLogin(
        userId: userId,
        password: password,
      );

      if (patient == null) {
        showErrorDialog('রোগীর তথ্য মেলেনি');
        return;
      }

      showLoginSuccessDialog(
        onOk: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDashboardScreen(patient: patient),
            ),
          );
        },
      );
    }
  }

  void showLoginSuccessDialog({
    required VoidCallback onOk,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'লগইন সফল হয়েছে',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'আপনি সফলভাবে লগইন করেছেন।',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onOk();
              },
              child: const Text('ঠিক আছে'),
            ),
          ],
        );
      },
    );
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'লগইন ব্যর্থ হয়েছে',
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('ঠিক আছে'),
            ),
          ],
        );
      },
    );
  }

  void openCreateAccountPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CaregiverAccountScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'লগ ইন করুন',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFB144F5),
                  Color(0xFFFF2D8C),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(34, 14, 34, 24),
          children: [
            const Text(
              'আপনি কোন ধরনের ইউজার?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF344054),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RoleCard(
                    title: 'পরিচর্যাকারী',
                    icon: Icons.manage_accounts_outlined,
                    isSelected: selectedRole == LoginRole.caregiver,
                    onTap: () {
                      setState(() {
                        selectedRole = LoginRole.caregiver;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RoleCard(
                    title: 'রোগী',
                    icon: Icons.person_outline,
                    isSelected: selectedRole == LoginRole.patient,
                    onTap: () {
                      setState(() {
                        selectedRole = LoginRole.patient;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LoginInputField(
              controller: userIdController,
              label: 'ইউজার আইডি',
              hint: 'আপনার ইউজার আইডি লিখুন',
              icon: Icons.key,
            ),
            const SizedBox(height: 14),
            LoginInputField(
              controller: passwordController,
              label: 'পাসওয়ার্ড',
              hint: 'আপনার পাসওয়ার্ড লিখুন',
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: login,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  backgroundColor: Colors.transparent,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFB144F5),
                        Color(0xFFFF2D8C),
                      ],
                    ),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'লগ ইন করুন',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: openCreateAccountPage,
              child: const Text(
                'একাউন্ট নেই? নতুন একাউন্ট তৈরি করুন',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = isSelected ? const Color(0xFFB144F5) : Colors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        height: 102,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isSelected ? const Color(0xFFB144F5) : const Color(0xFFE4E7EC),
            width: isSelected ? 1.7 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selectedColor,
              size: 38,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginInputField extends StatelessWidget {
  const LoginInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: const Color(0xFF344054),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF344054),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF8A8F98),
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: Color(0xFFD0D5DD),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: Color(0xFFD0D5DD),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: Color(0xFFB144F5),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}