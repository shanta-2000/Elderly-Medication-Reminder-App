import 'dart:io';

import 'package:flutter/material.dart';

import '../models/patient_model.dart';
import '../services/firebase_database_service.dart';
import '../utils/dose_status_helper.dart';
import 'patient_details_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({
    super.key,
    required this.patients,
  });

  final List<Patient> patients;

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  late List<Patient> localPatients;

  @override
  void initState() {
    super.initState();
    localPatients = List<Patient>.from(widget.patients);
  }

  @override
  void didUpdateWidget(covariant PatientListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.patients != widget.patients) {
      localPatients = List<Patient>.from(widget.patients);
    }
  }

  Future<void> openPatientDetails(Patient patient) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailsScreen(patient: patient),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {
        localPatients.removeWhere(
              (item) => item.id == patient.id,
        );
      });
      return;
    }

    if (result is Patient) {
      setState(() {
        final index = localPatients.indexWhere(
              (item) => item.id == result.id,
        );

        if (index != -1) {
          localPatients[index] = result;
        }
      });
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final patients = localPatients;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'রোগীদের তথ্য',
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'রোগী নির্বাচন করুন',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF344054),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${patients.length} জন',
                    style: const TextStyle(
                      color: Color(0xFF7E22CE),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (patients.isEmpty)
              const EmptyPatientListCard()
            else
              ...patients.map(
                    (patient) => PatientCard(
                  key: ValueKey('${patient.id}_${patient.photoUrl}'),
                  patient: patient,
                  onTap: () => openPatientDetails(patient),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EmptyPatientListCard extends StatelessWidget {
  const EmptyPatientListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE4E7EC),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.people_alt_outlined,
            size: 42,
            color: Color(0xFFD0D5DD),
          ),
          SizedBox(height: 10),
          Text(
            'এখনো কোনো রোগী যোগ করা হয়নি।',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF667085),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class PatientCard extends StatelessWidget {
  const PatientCard({
    super.key,
    required this.patient,
    required this.onTap,
  });

  final Patient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MedicineEntry>>(
      stream: FirebaseDatabaseService.instance.watchMedicinesByPatient(
        patient.id,
      ),
      builder: (context, medicineSnapshot) {
        final medicines = medicineSnapshot.data ?? [];
        final totalMedicines = medicines.length;

        final todaySummary = helperPatientSummaryForDate(
          medicines: medicines,
          date: DateTime.now(),
        );

        return Material(
          color: Colors.white,
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PatientPhoto(
                        photoPath: patient.photoPath,
                        photoUrl: patient.photoUrl,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PatientBasicInfo(patient: patient),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 15,
                        color: Color(0xFF98A2B3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PatientDoseStatPanel(
                    totalMedicines: totalMedicines,
                    summary: todaySummary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PatientBasicInfo extends StatelessWidget {
  const PatientBasicInfo({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          patient.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          'বয়স: ${patient.age} বছর',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF344054),
          ),
        ),
        const SizedBox(height: 6),
        if (patient.diseaseList.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF1E8FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              patient.diseaseList,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8A2BE2),
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          const Text(
            'সমস্যা উল্লেখ করা হয়নি',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF667085),
            ),
          ),
      ],
    );
  }
}

class PatientDoseStatPanel extends StatelessWidget {
  const PatientDoseStatPanel({
    super.key,
    required this.totalMedicines,
    required this.summary,
  });

  final int totalMedicines;
  final DoseSummary summary;

  @override
  Widget build(BuildContext context) {
    final totalDoses = summary.total;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE4E7EC),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PatientStatBox(
                  value: totalMedicines.toString(),
                  label: 'ওষুধ',
                  valueColor: Colors.black,
                ),
              ),
              Expanded(
                child: PatientStatBox(
                  value: totalDoses.toString(),
                  label: 'আজ ডোজ',
                  valueColor: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: PatientStatBox(
                  value: '${summary.taken}/$totalDoses',
                  label: 'নিয়েছে',
                  valueColor: const Color(0xFF16A34A),
                ),
              ),
              Expanded(
                child: PatientStatBox(
                  value: '${summary.pending}/$totalDoses',
                  label: 'Pending',
                  valueColor: const Color(0xFFEA580C),
                ),
              ),
              Expanded(
                child: PatientStatBox(
                  value: '${summary.missed}/$totalDoses',
                  label: 'খায়নি',
                  valueColor: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PatientPhoto extends StatelessWidget {
  const PatientPhoto({
    super.key,
    required this.photoPath,
    required this.photoUrl,
  });

  final String photoPath;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          photoUrl,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const DefaultPatientIcon();
          },
        ),
      );
    }

    if (photoPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(photoPath),
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const DefaultPatientIcon();
          },
        ),
      );
    }

    return const DefaultPatientIcon();
  }
}

class DefaultPatientIcon extends StatelessWidget {
  const DefaultPatientIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
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
}

class PatientStatBox extends StatelessWidget {
  const PatientStatBox({
    super.key,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}