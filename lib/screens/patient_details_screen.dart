import 'dart:io';

import 'package:flutter/material.dart';

import '../models/patient_model.dart';
import '../services/cloudinary_service.dart';
import '../services/firebase_database_service.dart';
import '../utils/dose_status_helper.dart';
import 'add_medicine_screen.dart';
import 'edit_patient_screen.dart';

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
  bool isSavingMedicine = false;
  bool isDeletingPatient = false;

  late Patient currentPatient;

  @override
  void initState() {
    super.initState();
    currentPatient = widget.patient;
  }

  Future<void> openEditPatientScreen() async {
    final Patient? updatedPatient = await Navigator.push<Patient>(
      context,
      MaterialPageRoute(
        builder: (context) => EditPatientScreen(
          patient: currentPatient,
        ),
      ),
    );

    if (!mounted || updatedPatient == null) return;

    setState(() {
      currentPatient = updatedPatient;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('রোগীর তথ্য আপডেট হয়েছে'),
      ),
    );
  }

  Future<void> confirmDeletePatient() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'রোগী মুছে ফেলবেন?',
            textAlign: TextAlign.center,
          ),
          content: Text(
            '${currentPatient.name} মুছে ফেললে এই রোগীর সব ওষুধ ও activity log মুছে যাবে।',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await deletePatient();
    }
  }

  Future<void> deletePatient() async {
    if (currentPatient.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('রোগীর Firebase ID পাওয়া যায়নি'),
        ),
      );
      return;
    }

    setState(() {
      isDeletingPatient = true;
    });

    try {
      await FirebaseDatabaseService.instance.deletePatientWithRelatedData(
        currentPatient.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('রোগী, ওষুধ ও activity log মুছে ফেলা হয়েছে'),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('রোগী মুছে ফেলা যায়নি: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isDeletingPatient = false;
        });
      }
    }
  }

  Future<void> openAddMedicineScreen() async {
    final MedicineEntry? newMedicine = await Navigator.push<MedicineEntry>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(
          patientName: currentPatient.name,
        ),
      ),
    );

    if (!mounted || newMedicine == null) return;

    await saveMedicineToFirebase(
      medicineFromEditor: newMedicine,
      existingMedicine: null,
    );
  }

  Future<void> openEditMedicineScreen(MedicineEntry medicine) async {
    final MedicineEntry? editedMedicine = await Navigator.push<MedicineEntry>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(
          patientName: currentPatient.name,
          existingMedicine: medicine,
        ),
      ),
    );

    if (!mounted || editedMedicine == null) return;

    await saveMedicineToFirebase(
      medicineFromEditor: editedMedicine,
      existingMedicine: medicine,
    );
  }

  Future<void> saveMedicineToFirebase({
    required MedicineEntry medicineFromEditor,
    required MedicineEntry? existingMedicine,
  }) async {
    if (currentPatient.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('রোগীর Firebase ID পাওয়া যায়নি'),
        ),
      );
      return;
    }

    setState(() {
      isSavingMedicine = true;
    });

    try {
      String finalImageUrl = medicineFromEditor.imageUrl;

      final isNewImageSelected = medicineFromEditor.imagePath.isNotEmpty &&
          medicineFromEditor.imagePath != (existingMedicine?.imagePath ?? '');

      if (isNewImageSelected) {
        finalImageUrl = await CloudinaryService.uploadImage(
          imagePath: medicineFromEditor.imagePath,
        );
      }

      final medicineToSave = medicineFromEditor.copyWith(
        id: existingMedicine?.id ?? '',
        caregiverId: currentPatient.caregiverId,
        patientId: currentPatient.id,
        imageUrl: finalImageUrl,
      );

      await FirebaseDatabaseService.instance.saveMedicine(medicineToSave);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingMedicine == null
                ? 'ওষুধ Firestore-এ সংরক্ষণ হয়েছে'
                : 'ওষুধ আপডেট হয়েছে',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ওষুধ সংরক্ষণ করা যায়নি: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSavingMedicine = false;
        });
      }
    }
  }

  Future<void> confirmDeleteMedicine(MedicineEntry medicine) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'ওষুধ মুছে ফেলবেন?',
            textAlign: TextAlign.center,
          ),
          content: Text(
            '${medicine.name} মুছে ফেললে এই ওষুধটি রোগীর তালিকা থেকে চলে যাবে।',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await deleteMedicine(medicine);
    }
  }

  Future<void> deleteMedicine(MedicineEntry medicine) async {
    try {
      await FirebaseDatabaseService.instance.deleteMedicine(medicine.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ওষুধ মুছে ফেলা হয়েছে'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ওষুধ মুছে ফেলা যায়নি: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final basePatient = currentPatient;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            PatientDetailsHeader(
              patient: basePatient,
              isDeletingPatient: isDeletingPatient,
              onEditPatient: openEditPatientScreen,
              onDeletePatient: confirmDeletePatient,
            ),
            Expanded(
              child: StreamBuilder<List<MedicineEntry>>(
                stream: FirebaseDatabaseService.instance
                    .watchMedicinesByPatient(basePatient.id),
                builder: (context, medicineSnapshot) {
                  if (medicineSnapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'ওষুধের তথ্য লোড করা যায়নি:\n${medicineSnapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  final medicines = medicineSnapshot.data ?? [];

                  return StreamBuilder<List<PatientActivityLog>>(
                    stream: FirebaseDatabaseService.instance
                        .watchActivityLogsByPatient(basePatient.id),
                    builder: (context, activitySnapshot) {
                      final logs = activitySnapshot.data ?? [];

                      final todaySummary = helperPatientSummaryForDate(
                        medicines: medicines,
                        date: DateTime.now(),
                      );

                      final patient = basePatient.copyWith(
                        medicines: medicines,
                        activityLogs: logs,
                      );

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                        children: [
                          if (medicineSnapshot.connectionState ==
                              ConnectionState.waiting)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: LinearProgressIndicator(),
                            ),
                          TodayDoseSummarySection(
                            summary: todaySummary,
                          ),
                          const SizedBox(height: 14),
                          MedicineListSection(
                            key: ValueKey(
                              '${patient.medicines.length}_${patient.activityLogs.length}_$isSavingMedicine',
                            ),
                            medicines: patient.medicines,
                            isSavingMedicine: isSavingMedicine,
                            onAddMedicine: openAddMedicineScreen,
                            onEditMedicine: openEditMedicineScreen,
                            onDeleteMedicine: confirmDeleteMedicine,
                          ),
                          const SizedBox(height: 14),
                          ActivitySection(patient: patient),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TodayDoseSummarySection extends StatelessWidget {
  const TodayDoseSummarySection({
    super.key,
    required this.summary,
  });

  final DoseSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.total;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                value: total.toString(),
                label: 'আজ ডোজ',
                backgroundColor: const Color(0xFFF2F7FF),
                borderColor: const Color(0xFFD8E7FF),
                valueColor: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                value: '${summary.taken}/$total',
                label: 'নিয়েছে',
                backgroundColor: const Color(0xFFEFFAF2),
                borderColor: const Color(0xFF9AE6B4),
                valueColor: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatCard(
                value: '${summary.pending}/$total',
                label: 'Pending',
                backgroundColor: const Color(0xFFFFF7E6),
                borderColor: const Color(0xFFFFD58A),
                valueColor: const Color(0xFFEA580C),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                value: '${summary.missed}/$total',
                label: 'খায়নি',
                backgroundColor: const Color(0xFFFFF1F1),
                borderColor: const Color(0xFFFFB4B4),
                valueColor: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PatientDetailsHeader extends StatelessWidget {
  const PatientDetailsHeader({
    super.key,
    required this.patient,
    required this.isDeletingPatient,
    required this.onEditPatient,
    required this.onDeletePatient,
  });

  final Patient patient;
  final bool isDeletingPatient;
  final VoidCallback onEditPatient;
  final VoidCallback onDeletePatient;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                const Expanded(
                  child: Text(
                    'রোগীর বিস্তারিত তথ্য',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: isDeletingPatient ? null : onEditPatient,
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: isDeletingPatient ? null : onDeletePatient,
                  icon: isDeletingPatient
                      ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
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
                PatientLargePhoto(
                  photoPath: patient.photoPath,
                  photoUrl: patient.photoUrl,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: PatientInfoText(patient: patient),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PatientLargePhoto extends StatelessWidget {
  const PatientLargePhoto({
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
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          photoUrl,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const DefaultPatientLargeIcon();
          },
        ),
      );
    }

    if (photoPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(photoPath),
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const DefaultPatientLargeIcon();
          },
        ),
      );
    }

    return const DefaultPatientLargeIcon();
  }
}

class DefaultPatientLargeIcon extends StatelessWidget {
  const DefaultPatientLargeIcon({super.key});

  @override
  Widget build(BuildContext context) {
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
              fontWeight: FontWeight.w800,
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
              fontWeight: FontWeight.w600,
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
    required this.isSavingMedicine,
    required this.onAddMedicine,
    required this.onEditMedicine,
    required this.onDeleteMedicine,
  });

  final List<MedicineEntry> medicines;
  final bool isSavingMedicine;
  final VoidCallback onAddMedicine;
  final void Function(MedicineEntry medicine) onEditMedicine;
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
              onTap: isSavingMedicine ? null : onAddMedicine,
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  const Icon(Icons.medication_outlined, size: 21),
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
                    child: isSavingMedicine
                        ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(
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
                  onEdit: () => onEditMedicine(medicine),
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
    required this.onEdit,
    required this.onDelete,
  });

  final MedicineEntry medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final todaySummary = helperMedicineSummaryForDate(
      medicine: medicine,
      date: DateTime.now(),
    );

    final takenDays = helperMedicineTakenDaysCount(medicine);
    final remainingDays = helperMedicineRemainingDaysCount(medicine);
    final totalDays = medicine.totalDays;
    final progressValue = totalDays == 0 ? 0.0 : takenDays / totalDays;

    Color statusColor = const Color(0xFF16A34A);
    Color statusBackground = const Color(0xFFEFFAF2);

    if (medicine.statusText == 'Complete') {
      statusColor = const Color(0xFF2563EB);
      statusBackground = const Color(0xFFE8F0FF);
    } else if (medicine.statusText == 'Upcoming') {
      statusColor = const Color(0xFFEA580C);
      statusBackground = const Color(0xFFFFF4E5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              MedicineSmallPhoto(
                imagePath: medicine.imagePath,
                imageUrl: medicine.imageUrl,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MedicineMainInfo(
                  medicine: medicine,
                  statusColor: statusColor,
                  statusBackground: statusBackground,
                ),
              ),
              MedicineActionButtons(
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SmallMedicineInfo(
                  title: 'শুরু',
                  value: helperFormatShortDate(medicine.startDate),
                ),
              ),
              Expanded(
                child: SmallMedicineInfo(
                  title: 'শেষ',
                  value: helperFormatShortDate(medicine.endDate),
                ),
              ),
              Expanded(
                child: SmallMedicineInfo(
                  title: 'সময়কাল',
                  value: '${medicine.totalDays} দিন',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TodayMedicineDosePanel(
            summary: todaySummary,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MedicineDayBox(
                  title: 'সম্পন্ন দিন',
                  value: '$takenDays দিন',
                  backgroundColor: const Color(0xFFEFFAF2),
                  textColor: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MedicineDayBox(
                  title: 'বাকি দিন',
                  value: '$remainingDays দিন',
                  backgroundColor: const Color(0xFFFFF4E5),
                  textColor: const Color(0xFFEA580C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressValue.clamp(0.0, 1.0),
            minHeight: 7,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: const Color(0xFFE5E7EB),
            color: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 10),
          MedicineDateProgressStrip(medicine: medicine),
        ],
      ),
    );
  }
}

class MedicineMainInfo extends StatelessWidget {
  const MedicineMainInfo({
    super.key,
    required this.medicine,
    required this.statusColor,
    required this.statusBackground,
  });

  final MedicineEntry medicine;
  final Color statusColor;
  final Color statusBackground;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                medicine.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: statusBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                medicine.statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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
      ],
    );
  }
}

class MedicineActionButtons extends StatelessWidget {
  const MedicineActionButtons({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          onPressed: onEdit,
          icon: const Icon(
            Icons.edit,
            color: Color(0xFF2563EB),
            size: 18,
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          onPressed: onDelete,
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
            size: 19,
          ),
        ),
      ],
    );
  }
}

class TodayMedicineDosePanel extends StatelessWidget {
  const TodayMedicineDosePanel({
    super.key,
    required this.summary,
  });

  final DoseSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.total;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFE4E7EC),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SmallDoseText(
              label: 'আজ ডোজ',
              value: total.toString(),
              color: const Color(0xFF2563EB),
            ),
          ),
          Expanded(
            child: SmallDoseText(
              label: 'নিয়েছে',
              value: '${summary.taken}/$total',
              color: const Color(0xFF16A34A),
            ),
          ),
          Expanded(
            child: SmallDoseText(
              label: 'Pending',
              value: '${summary.pending}/$total',
              color: const Color(0xFFEA580C),
            ),
          ),
          Expanded(
            child: SmallDoseText(
              label: 'খায়নি',
              value: '${summary.missed}/$total',
              color: const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}

class SmallDoseText extends StatelessWidget {
  const SmallDoseText({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF344054),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class SmallMedicineInfo extends StatelessWidget {
  const SmallMedicineInfo({
    super.key,
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF344054),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class MedicineDayBox extends StatelessWidget {
  const MedicineDayBox({
    super.key,
    required this.title,
    required this.value,
    required this.backgroundColor,
    required this.textColor,
  });

  final String title;
  final String value;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class MedicineDateProgressStrip extends StatelessWidget {
  const MedicineDateProgressStrip({
    super.key,
    required this.medicine,
  });

  final MedicineEntry medicine;

  @override
  Widget build(BuildContext context) {
    final dates = helperMedicineDates(medicine);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: dates.map((date) {
          return DailyDoseBox(
            medicine: medicine,
            date: date,
          );
        }).toList(),
      ),
    );
  }
}

class DailyDoseBox extends StatelessWidget {
  const DailyDoseBox({
    super.key,
    required this.medicine,
    required this.date,
  });

  final MedicineEntry medicine;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final summary = helperMedicineSummaryForDate(
      medicine: medicine,
      date: date,
    );

    final displayText = helperSmallStatusText(summary);

    Color textColor = const Color(0xFF667085);
    Color backgroundColor = Colors.white;
    Color borderColor = const Color(0xFFE4E7EC);

    if (summary.isAllTaken) {
      textColor = const Color(0xFF16A34A);
      backgroundColor = const Color(0xFFEFFAF2);
      borderColor = const Color(0xFFBBF7D0);
    } else if (summary.isAllMissed) {
      textColor = const Color(0xFFDC2626);
      backgroundColor = const Color(0xFFFFF1F1);
      borderColor = const Color(0xFFFECACA);
    } else if (summary.isPartial) {
      textColor = const Color(0xFFEA580C);
      backgroundColor = const Color(0xFFFFF7E6);
      borderColor = const Color(0xFFFFD58A);
    }

    return Container(
      width: 62,
      margin: const EdgeInsets.only(right: 7),
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            helperFormatShortDate(date),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF344054),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            displayText,
            style: TextStyle(
              color: textColor,
              fontSize: displayText.length > 1 ? 13 : 18,
              fontWeight: FontWeight.w900,
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
    required this.imageUrl,
  });

  final String imagePath;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const DefaultMedicineIcon();
          },
        ),
      );
    }

    if (imagePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(imagePath),
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const DefaultMedicineIcon();
          },
        ),
      );
    }

    return const DefaultMedicineIcon();
  }
}

class DefaultMedicineIcon extends StatelessWidget {
  const DefaultMedicineIcon({super.key});

  @override
  Widget build(BuildContext context) {
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
}

class ActivitySection extends StatelessWidget {
  const ActivitySection({
    super.key,
    required this.patient,
  });

  final Patient patient;

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
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 14),
            if (logs.isEmpty)
              const Column(
                children: [
                  SizedBox(height: 14),
                  Center(
                    child: Icon(
                      Icons.access_time,
                      size: 44,
                      color: Color(0xFFD0D5DD),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'আজ কোনো কার্যকলাপ নেই',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ),
                ],
              )
            else
              ...logs.map((log) {
                final isTaken = log.status == 'খেয়েছে';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 78,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              helperFormatFullDate(log.date),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF344054),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              log.periodName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF344054),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        helperFormatActivityTime(log.time),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF667085),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isTaken ? Icons.check_circle : Icons.cancel,
                        color: isTaken
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${log.medicineName} ${log.status}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isTaken
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                            fontWeight: FontWeight.w700,
                          ),
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