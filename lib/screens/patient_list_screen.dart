import 'dart:io';

import 'package:flutter/material.dart';

import '../models/patient_model.dart';
import 'patient_details_screen.dart';

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({
    super.key,
    required this.patients,
  });

  final List<Patient> patients;

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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            const Text(
              'রোগী নির্বাচন করুন',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF344054),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            if (patients.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE4E7EC),
                  ),
                ),
                child: const Text(
                  'এখনো কোনো রোগী যোগ করা হয়নি।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF667085),
                  ),
                ),
              )
            else
              ...patients.map(
                    (patient) => PatientCard(patient: patient),
              ),
          ],
        ),
      ),
    );
  }
}

class PatientCard extends StatelessWidget {
  const PatientCard({
    super.key,
    required this.patient,
  });

  final Patient patient;

  void openPatientDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailsScreen(patient: patient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => openPatientDetails(context),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PatientPhoto(photoPath: patient.photoPath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
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
                      ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          PatientStatBox(
                            value: patient.totalMedicines.toString(),
                            label: 'ওষুধ',
                            valueColor: Colors.black,
                          ),
                          PatientStatBox(
                            value: patient.takenToday.toString(),
                            label: 'আজ নিয়েছে',
                            valueColor: Colors.green,
                          ),
                          PatientStatBox(
                            value: patient.totalLogs.toString(),
                            label: 'মোট লগ',
                            valueColor: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatientPhoto extends StatelessWidget {
  const PatientPhoto({
    super.key,
    required this.photoPath,
  });

  final String photoPath;

  @override
  Widget build(BuildContext context) {
    if (photoPath.isEmpty) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.person,
          color: Color(0xFFB144F5),
          size: 31,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.file(
        File(photoPath),
        width: 52,
        height: 52,
        fit: BoxFit.cover,
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
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}