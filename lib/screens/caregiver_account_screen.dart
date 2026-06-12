import 'package:flutter/material.dart';
import 'caregiver_dashboard_screen.dart';
import '../data/app_data.dart';
import '../models/caregiver_model.dart';

class CaregiverAccountScreen extends StatefulWidget {
  const CaregiverAccountScreen({super.key});

  @override
  State<CaregiverAccountScreen> createState() => _CaregiverAccountScreenState();
}

class _CaregiverAccountScreenState extends State<CaregiverAccountScreen> {
  final userIdController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void dispose() {
    userIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void createAccount() {
    final userId = userIdController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final fullName = fullNameController.text.trim();
    final phone = phoneController.text.trim();

    if (userId.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        fullName.isEmpty ||
        phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অনুগ্রহ করে প্রয়োজনীয় তথ্য পূরণ করুন'),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('পাসওয়ার্ড মিলছে না'),
        ),
      );
      return;
    }
    AppData.saveCaregiver(
      Caregiver(
        userId: userId,
        password: password,
        fullName: fullName,
        phone: phone,
        email: emailController.text.trim(),
        address: addressController.text.trim(),
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CaregiverDashboardScreen(
          caregiverName: fullName,
          showAccountCreatedDialog: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'পরিচর্যাকরীর একাউন্ট তৈরি',
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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(5, 10, 5, 12),
                children: [
                  CustomInputField(
                    controller: userIdController,
                    label: 'ইউজার আইডি *',
                    hint: 'যেমন: rahima123',
                    icon: Icons.key,
                  ),
                  CustomInputField(
                    controller: passwordController,
                    label: 'পাসওয়ার্ড *',
                    hint: 'কমপক্ষে ৪ অক্ষর',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  CustomInputField(
                    controller: confirmPasswordController,
                    label: 'পাসওয়ার্ড নিশ্চিত করুন *',
                    hint: 'আবার পাসওয়ার্ড লিখুন',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  CustomInputField(
                    controller: fullNameController,
                    label: 'পূর্ণ নাম *',
                    hint: 'যেমন: রহিমা খাতুন',
                    icon: Icons.person_outline,
                  ),
                  CustomInputField(
                    controller: phoneController,
                    label: 'ফোন নম্বর *',
                    hint: 'যেমন: 01712345678',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  CustomInputField(
                    controller: emailController,
                    label: 'ইমেইল (ঐচ্ছিক)',
                    hint: 'যেমন: rahima@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  CustomInputField(
                    controller: addressController,
                    label: 'ঠিকানা',
                    hint: 'যেমন: ঢাকা, বাংলাদেশ',
                    icon: Icons.location_on_outlined,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 8, 5, 8),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: createAccount,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
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
                        'একাউন্ট তৈরি করুন',
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
            ),
          ],
        ),
      ),
    );
  }
}

class CustomInputField extends StatelessWidget {
  const CustomInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: const Color(0xFF344054),
              ),
              const SizedBox(width: 5),
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
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: obscureText ? 1 : maxLines,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
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
      ),
    );
  }
}

