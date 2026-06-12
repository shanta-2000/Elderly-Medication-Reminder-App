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
  final durationController = TextEditingController(text: '7');

  String medicineImagePath = '';
  final List<String> medicineTimes = [];

  DateTime startDate = dateOnly(DateTime.now());
  DateTime? customEndDate;

  bool useCustomEndDate = false;
  String selectedDurationUnit = 'দিন';

  @override
  void dispose() {
    medicineNameController.dispose();
    instructionController.dispose();
    durationController.dispose();
    super.dispose();
  }

  DateTime addMonths(DateTime date, int months) {
    return DateTime(date.year, date.month + months, date.day);
  }

  DateTime calculateEndDate() {
    if (useCustomEndDate && customEndDate != null) {
      return dateOnly(customEndDate!);
    }

    final value = int.tryParse(durationController.text.trim()) ?? 0;

    if (selectedDurationUnit == 'দিন') {
      return startDate.add(Duration(days: value - 1));
    }

    if (selectedDurationUnit == 'সপ্তাহ') {
      return startDate.add(Duration(days: (value * 7) - 1));
    }

    if (selectedDurationUnit == 'মাস') {
      return addMonths(startDate, value).subtract(const Duration(days: 1));
    }

    return startDate;
  }

  int calculateTotalDays() {
    final endDate = calculateEndDate();
    return dateOnly(endDate).difference(dateOnly(startDate)).inDays + 1;
  }

  String formatDate(DateTime date) {
    const months = [
      'জানু',
      'ফেব',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগ',
      'সেপ্ট',
      'অক্টো',
      'নভে',
      'ডিসে',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
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

  Future<void> pickStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate != null) {
      setState(() {
        startDate = dateOnly(pickedDate);

        if (customEndDate != null &&
            dateOnly(customEndDate!).isBefore(startDate)) {
          customEndDate = startDate;
        }
      });
    }
  }

  Future<void> pickCustomEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: customEndDate ?? startDate,
      firstDate: startDate,
      lastDate: DateTime(2035),
    );

    if (pickedDate != null) {
      setState(() {
        customEndDate = dateOnly(pickedDate);
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
    final durationValue = int.tryParse(durationController.text.trim());

    if (medicineName.isEmpty || medicineTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ওষুধের নাম ও সময় দিন'),
        ),
      );
      return;
    }

    if (!useCustomEndDate && (durationValue == null || durationValue <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সঠিক সময়কাল দিন'),
        ),
      );
      return;
    }

    if (useCustomEndDate && customEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('শেষ তারিখ নির্বাচন করুন'),
        ),
      );
      return;
    }

    final endDate = calculateEndDate();

    if (endDate.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('শেষ তারিখ শুরু তারিখের আগে হতে পারে না'),
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
      startDate: startDate,
      endDate: endDate,
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
          content: Text(
            'শুরু: ${formatDate(startDate)}\nশেষ: ${formatDate(endDate)}\nমোট সময়: ${calculateTotalDays()} দিন',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
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
    final endDate = calculateEndDate();
    final totalDays = calculateTotalDays();

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
              hint: 'যেমন: Napa',
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

            const SizedBox(height: 16),
            const Text(
              'শুরু তারিখ',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF344054),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DatePickerBox(
              text: formatDate(startDate),
              onTap: pickStartDate,
            ),

            const SizedBox(height: 16),
            const Text(
              'সময়কাল নির্বাচন করুন',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF344054),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DurationModeSelector(
              useCustomEndDate: useCustomEndDate,
              onChanged: (value) {
                setState(() {
                  useCustomEndDate = value;
                });
              },
            ),

            const SizedBox(height: 12),
            if (!useCustomEndDate)
              Row(
                children: [
                  Expanded(
                    child: MedicineInputField(
                      controller: durationController,
                      label: 'সময়কাল',
                      hint: 'যেমন: 7',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DurationUnitDropdown(
                      value: selectedDurationUnit,
                      onChanged: (value) {
                        setState(() {
                          selectedDurationUnit = value;
                        });
                      },
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'শেষ তারিখ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF344054),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DatePickerBox(
                    text: customEndDate == null
                        ? 'শেষ তারিখ নির্বাচন করুন'
                        : formatDate(customEndDate!),
                    onTap: pickCustomEndDate,
                  ),
                ],
              ),

            const SizedBox(height: 14),
            DurationSummaryBox(
              startDateText: formatDate(startDate),
              endDateText: formatDate(endDate),
              totalDays: totalDays,
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

class DatePickerBox extends StatelessWidget {
  const DatePickerBox({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD0D5DD)),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF667085),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF344054),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF667085),
            ),
          ],
        ),
      ),
    );
  }
}

class DurationModeSelector extends StatelessWidget {
  const DurationModeSelector({
    super.key,
    required this.useCustomEndDate,
    required this.onChanged,
  });

  final bool useCustomEndDate;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DurationModeBox(
            title: 'সংখ্যা ভিত্তিক',
            isSelected: !useCustomEndDate,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DurationModeBox(
            title: 'কাস্টম তারিখ',
            isSelected: useCustomEndDate,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class DurationModeBox extends StatelessWidget {
  const DurationModeBox({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDE7F6) : Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFB144F5)
                : const Color(0xFFD0D5DD),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color(0xFFB144F5)
                  : const Color(0xFF667085),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF7E22CE)
                      : const Color(0xFF344054),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DurationUnitDropdown extends StatelessWidget {
  const DurationUnitDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'একক',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF344054),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD0D5DD)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'দিন',
                  child: Text('দিন'),
                ),
                DropdownMenuItem(
                  value: 'সপ্তাহ',
                  child: Text('সপ্তাহ'),
                ),
                DropdownMenuItem(
                  value: 'মাস',
                  child: Text('মাস'),
                ),
              ],
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class DurationSummaryBox extends StatelessWidget {
  const DurationSummaryBox({
    super.key,
    required this.startDateText,
    required this.endDateText,
    required this.totalDays,
  });

  final String startDateText;
  final String endDateText;
  final int totalDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'সময়কাল সারাংশ',
            style: TextStyle(
              color: Color(0xFF344054),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text('শুরু: $startDateText'),
          Text('শেষ: $endDateText'),
          Text('মোট সময়: $totalDays দিন'),
        ],
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
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

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
          keyboardType: keyboardType,
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