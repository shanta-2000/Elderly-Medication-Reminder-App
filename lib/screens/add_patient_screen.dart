import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/patient_model.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final userIdController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final patientNameController = TextEditingController();
  final ageController = TextEditingController();
  final diseaseController = TextEditingController();

  String selectedPhotoPath = '';

  @override
  void dispose() {
    userIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    patientNameController.dispose();
    ageController.dispose();
    diseaseController.dispose();
    super.dispose();
  }

  Future<void> pickPatientPhoto() async {
    final picker = ImagePicker();

    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      setState(() {
        selectedPhotoPath = pickedImage.path;
      });
    }
  }

  void addPatient() {
    final userId = userIdController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final patientName = patientNameController.text.trim();
    final age = ageController.text.trim();

    if (userId.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        patientName.isEmpty ||
        age.isEmpty) {
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

    final patient = Patient(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      password: password,
      name: patientName,
      age: age,
      photoPath: selectedPhotoPath,
      diseaseList: diseaseController.text.trim(),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'রোগী যোগ হয়েছে',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'রোগীর তথ্য সফলভাবে যোগ করা হয়েছে।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context, patient);
              },
              child: const Text('ঠিক আছে'),
            ),
          ],
        );
      },
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
            'নতুন রোগী যোগ করুন',
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
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                'রোগীর তথ্য ও লগইন তথ্য দিন',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF344054),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 20),
                children: [
                  CustomInputField(
                    controller: userIdController,
                    label: 'রোগীর ইউজার আইডি *',
                    hint: 'যেমন: karim123',
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
                  const Divider(height: 28),
                  CustomInputField(
                    controller: patientNameController,
                    label: 'রোগীর নাম *',
                    hint: 'যেমন: আব্দুল করিম',
                    icon: Icons.person_outline,
                  ),
                  CustomInputField(
                    controller: ageController,
                    label: 'বয়স *',
                    hint: 'যেমন: 72',
                    icon: Icons.calendar_month_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'রোগীর ছবি',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF344054),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      PatientPhotoPreview(photoPath: selectedPhotoPath),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: pickPatientPhoto,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('গ্যালারি থেকে ছবি নিন'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CustomInputField(
                    controller: diseaseController,
                    label: 'রোগের তালিকা (কমা দিয়ে আলাদা করুন)',
                    hint: 'যেমন: উচ্চ রক্তচাপ, ডায়াবেটিস',
                    icon: Icons.favorite_border,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: addPatient,
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
                            'রোগী যোগ করুন',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientPhotoPreview extends StatelessWidget {
  const PatientPhotoPreview({
    super.key,
    required this.photoPath,
  });

  final String photoPath;

  @override
  Widget build(BuildContext context) {
    if (photoPath.isEmpty) {
      return Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.person,
          color: Color(0xFFB144F5),
          size: 32,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.file(
        File(photoPath),
        width: 58,
        height: 58,
        fit: BoxFit.cover,
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
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
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
            keyboardType: keyboardType,
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