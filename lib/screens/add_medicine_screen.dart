import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/patient_model.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({
    super.key,
    required this.patientName,
  });

  final String patientName;

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final medicineNameController = TextEditingController();
  final instructionController = TextEditingController();

  String medicineImagePath = '';
  final List<String> medicineTimes = [];

  @override
  void dispose() {
    medicineNameController.dispose();
    instructionController.dispose();
    super.dispose();
  }

  Future<void> pickMedicineImage() async {
    final picker = ImagePicker();

    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      setState(() {
        medicineImagePath = pickedImage.path;
      });
    }
  }

  Future<void> addTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        medicineTimes.add(pickedTime.format(context));
      });
    }
  }

  void removeTime(String time) {
    setState(() {
      medicineTimes.remove(time);
    });
  }

  void saveMedicine() {
    final medicineName = medicineNameController.text.trim();

    if (medicineName.isEmpty || medicineTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ওষুধের নাম ও সময় দিন'),
        ),
      );
      return;
    }

    final medicine = MedicineEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: medicineName,
      imagePath: medicineImagePath,
      instruction: instructionController.text.trim(),
      times: List<String>.from(medicineTimes),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'ওষুধ সংরক্ষিত হয়েছে',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'রোগীর ওষুধের তালিকায় নতুন ওষুধ যোগ করা হয়েছে।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context, medicine);
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
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'নতুন ওষুধ যোগ করুন',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${widget.patientName} এর জন্য',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
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
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 24),
          children: [
            MedicineInputField(
              controller: medicineNameController,
              label: 'ওষুধের নাম *',
              hint: 'যেমন: রক্তচাপের ওষুধ',
            ),
            const SizedBox(height: 14),
            const Text(
              'ওষুধের ছবি',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF344054),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                MedicinePhotoPreview(imagePath: medicineImagePath),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: pickMedicineImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('গ্যালারি থেকে ছবি নিন'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            MedicineInputField(
              controller: instructionController,
              label: 'নির্দেশনা',
              hint: 'যেমন: খাবার পরে খেতে হবে',
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            const Text(
              'খাওয়ার সময় *',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF344054),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD0D5DD)),
                borderRadius: BorderRadius.circular(11),
              ),
              child: medicineTimes.isEmpty
                  ? const Text(
                '--:-- --',
                style: TextStyle(
                  color: Color(0xFF8A8F98),
                  fontSize: 15,
                ),
              )
                  : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: medicineTimes.map((time) {
                  return Chip(
                    label: Text(time),
                    deleteIcon: const Icon(Icons.close, size: 17),
                    onDeleted: () => removeTime(time),
                    backgroundColor: const Color(0xFFE8F0FF),
                    labelStyle: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: addTime,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('আরও সময় যোগ করুন'),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: saveMedicine,
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
                      'ওষুধ সংরক্ষণ করুন',
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
    );
  }
}

class MedicinePhotoPreview extends StatelessWidget {
  const MedicinePhotoPreview({
    super.key,
    required this.imagePath,
  });

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.medication_liquid,
          color: Color(0xFFB144F5),
          size: 34,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.file(
        File(imagePath),
        width: 64,
        height: 64,
        fit: BoxFit.cover,
      ),
    );
  }
}

class MedicineInputField extends StatelessWidget {
  const MedicineInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF344054),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
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