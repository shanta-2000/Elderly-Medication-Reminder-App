import 'dart:io';

import 'package:flutter/material.dart';

import '../models/patient_model.dart';
import 'add_medicine_screen.dart';

class PatientDetailsScreen extends StatefulWidget {
  const PatientDetailsScreen({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  Future<void> openAddMedicineScreen() async {
    final MedicineEntry? medicine = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(
          patientName: widget.patient.name,
        ),
      ),
    );

    if (medicine != null) {
      setState(() {
        widget.patient.medicines.add(medicine);
      });
    }
  }

  void deleteMedicine(MedicineEntry medicine) {
    setState(() {
      widget.patient.medicines.remove(medicine);
    });
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFB144F5),
                    Color(0xFFFF2D8C),
                  ],
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 54,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'রোগীর বিস্তারিত তথ্য',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.all(14),
                    width: double.infinity,
                    height: 166,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PatientLargePhoto(photoPath: patient.photoPath),
                        const SizedBox(width: 14),
                        Expanded(
                          child: PatientInfoText(patient: patient),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          value: patient.takenToday.toString(),
                          label: 'আজ খেয়েছে',
                          backgroundColor: const Color(0xFFEFFAF2),
                          borderColor: const Color(0xFF9AE6B4),
                          valueColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          value: patient.missedToday.toString(),
                          label: 'আজ খায়নি',
                          backgroundColor: const Color(0xFFFFF1F1),
                          borderColor: const Color(0xFFFFB4B4),
                          valueColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  MedicineListSection(
                    medicines: patient.medicines,
                    onAddMedicine: openAddMedicineScreen,
                    onDeleteMedicine: deleteMedicine,
                  ),
                  const SizedBox(height: 14),
                  ActivitySection(patient: widget.patient),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientLargePhoto extends StatelessWidget {
  const PatientLargePhoto({
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
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.person,
          color: Color(0xFFB144F5),
          size: 35,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(photoPath),
        width: 58,
        height: 58,
        fit: BoxFit.cover,
      ),
    );
  }
}

class PatientInfoText extends StatelessWidget {
  const PatientInfoText({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF344054),
        height: 1.35,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            patient.name,
            style: const TextStyle(
              fontSize: 17,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text('বয়স: ${patient.age} বছর'),
          Text(
            patient.diseaseList.isEmpty
                ? 'সমস্যা: উল্লেখ করা হয়নি'
                : 'সমস্যা: ${patient.diseaseList}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text('ইউজার আইডি: ${patient.userId}'),
          Text('পাসওয়ার্ড: ${patient.password}'),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class MedicineListSection extends StatelessWidget {
  const MedicineListSection({
    super.key,
    required this.medicines,
    required this.onAddMedicine,
    required this.onDeleteMedicine,
  });

  final List<MedicineEntry> medicines;
  final VoidCallback onAddMedicine;
  final void Function(MedicineEntry medicine) onDeleteMedicine;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.12),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onAddMedicine,
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 21),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'ওষুধের তালিকা',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 31,
                    height: 31,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB144F5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (medicines.isEmpty)
              const EmptyMedicineView()
            else
              ...medicines.map(
                    (medicine) => MedicineTile(
                  medicine: medicine,
                  onDelete: () => onDeleteMedicine(medicine),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EmptyMedicineView extends StatelessWidget {
  const EmptyMedicineView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 44,
            color: Color(0xFFD0D5DD),
          ),
          SizedBox(height: 8),
          Text(
            'কোনো ওষুধ নেই',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}

class MedicineTile extends StatelessWidget {
  const MedicineTile({
    super.key,
    required this.medicine,
    required this.onDelete,
  });

  final MedicineEntry medicine;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          MedicineSmallPhoto(imagePath: medicine.imagePath),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                if (medicine.instruction.isNotEmpty)
                  Text(
                    medicine.instruction,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475467),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: medicine.times.map((time) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        time,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 3),
                const Text(
                  '০ দিন মিস',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.close,
              color: Colors.red,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class MedicineSmallPhoto extends StatelessWidget {
  const MedicineSmallPhoto({
    super.key,
    required this.imagePath,
  });

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.medication_liquid,
          color: Color(0xFFB144F5),
          size: 28,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(imagePath),
        width: 54,
        height: 54,
        fit: BoxFit.cover,
      ),
    );
  }
}

class ActivitySection extends StatelessWidget {
  const ActivitySection({
    super.key,
    required this.patient,
  });

  final Patient patient;

  String formatActivityTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : time.hour == 0
        ? 12
        : time.hour;

    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final logs = patient.activityLogs;

    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.12),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart, size: 22),
                SizedBox(width: 8),
                Text(
                  'সাম্প্রতিক কার্যকলাপ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (logs.isEmpty)
              const Column(
                children: [
                  SizedBox(height: 12),
                  Icon(
                    Icons.access_time,
                    size: 44,
                    color: Color(0xFFD0D5DD),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'আজ কোনো কার্যকলাপ নেই',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              )
            else
              ...logs.map((log) {
                final isTaken = log.status == 'খেয়েছে';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isTaken
                        ? const Color(0xFFEFFAF2)
                        : const Color(0xFFFFF1F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isTaken
                          ? const Color(0xFFBBF7D0)
                          : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isTaken ? Icons.check_circle : Icons.cancel,
                        color: isTaken
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${log.periodName}ে ${log.medicineName} ${log.status}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        formatActivityTime(log.time),
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}