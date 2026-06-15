import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/patient_model.dart';
import '../services/firebase_database_service.dart';
import '../services/session_service.dart';
import '../utils/dose_status_helper.dart';
import 'welcome_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  bool isUpdatingDose = false;

  late final ConfettiController confettiController;
  late final AudioPlayer audioPlayer;

  @override
  void initState() {
    super.initState();

    confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    confettiController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> playSuccessEffect({
    required String message,
  }) async {
    confettiController.play();

    try {
      await audioPlayer.stop();
      await audioPlayer.play(
        AssetSource('sounds/applause.mp3'),
      );
    } catch (error) {
      debugPrint('AUDIO PLAY ERROR: $error');
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'অভিনন্দন!',
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
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

  Future<void> playMissedEffect({
    required String message,
  }) async {
    try {
      await audioPlayer.stop();
      await audioPlayer.play(
        AssetSource('sounds/sad.mp3'),
      );
    } catch (error) {
      debugPrint('SAD AUDIO PLAY ERROR: $error');
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'মনে রাখবেন',
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
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

  void showSignOutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'সাইন আউট',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'আপনি কি সাইন আউট করতে চান?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await SessionService.clearLogin();
                AppData.clearSession();

                if (!mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                      (route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateDoseStatus({
    required MedicineEntry medicine,
    required String periodKey,
    required String result,
  }) async {
    if (isUpdatingDose) return;

    setState(() {
      isUpdatingDose = true;
    });

    try {
      final today = dateOnly(DateTime.now());
      final doseKey = helperDoseKey(today, periodKey);

      final takenDoseKeys = Set<String>.from(medicine.takenDoseKeys);
      final missedDoseKeys = Set<String>.from(medicine.missedDoseKeys);
      final takenPeriodKeys = Set<String>.from(medicine.takenPeriodKeys);
      final missedPeriodKeys = Set<String>.from(medicine.missedPeriodKeys);

      String statusText = '';

      if (result == 'taken') {
        takenDoseKeys.add(doseKey);
        missedDoseKeys.remove(doseKey);

        takenPeriodKeys.add(periodKey);
        missedPeriodKeys.remove(periodKey);

        statusText = 'খেয়েছে';
      } else if (result == 'missed') {
        missedDoseKeys.add(doseKey);
        takenDoseKeys.remove(doseKey);

        missedPeriodKeys.add(periodKey);
        takenPeriodKeys.remove(periodKey);

        statusText = 'খায়নি';
      } else {
        return;
      }

      final tempUpdatedMedicine = medicine.copyWith(
        takenDoseKeys: takenDoseKeys,
        missedDoseKeys: missedDoseKeys,
        takenPeriodKeys: takenPeriodKeys,
        missedPeriodKeys: missedPeriodKeys,
      );

      final todaySummary = helperMedicineSummaryForDate(
        medicine: tempUpdatedMedicine,
        date: today,
      );

      final updatedMedicine = tempUpdatedMedicine.copyWith(
        isTakenToday: todaySummary.isAllTaken,
        isMissedToday: todaySummary.missed > 0,
      );

      await FirebaseDatabaseService.instance.updateMedicineDoseStatus(
        updatedMedicine,
      );

      final log = PatientActivityLog(
        id: '',
        caregiverId: widget.patient.caregiverId,
        patientId: widget.patient.id,
        medicineId: updatedMedicine.id,
        medicineName: updatedMedicine.name,
        periodName: helperPeriodTitle(periodKey),
        status: statusText,
        time: DateTime.now(),
        date: today,
      );

      await FirebaseDatabaseService.instance.saveActivityLog(log);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${helperPeriodPossessive(periodKey)} ${updatedMedicine.name} $statusText হিসেবে সংরক্ষণ হয়েছে',
          ),
        ),
      );

      if (statusText == 'খেয়েছে') {
        await playSuccessEffect(
          message:
          '${helperPeriodPossessive(periodKey)} ${updatedMedicine.name} সম্পন্ন হয়েছে।',
        );
      } else if (statusText == 'খায়নি') {
        await playMissedEffect(
          message:
          '${helperPeriodPossessive(periodKey)} ${updatedMedicine.name} খাওয়া হয়নি। পরবর্তী ডোজ সময়মতো নেওয়ার চেষ্টা করুন।',
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('স্ট্যাটাস আপডেট করা যায়নি: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingDose = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final basePatient = widget.patient;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
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

                    final patient = basePatient.copyWith(
                      medicines: medicines,
                      activityLogs: logs,
                    );

                    final todaySummary = helperPatientSummaryForDate(
                      medicines: medicines,
                      date: DateTime.now(),
                    );

                    final todayPeriodKeys =
                    helperPatientScheduledPeriodsForDate(
                      medicines: medicines,
                      date: DateTime.now(),
                    );

                    return ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        PatientDashboardHeader(
                          patient: patient,
                          onSignOutTap: showSignOutDialog,
                        ),
                        if (medicineSnapshot.connectionState ==
                            ConnectionState.waiting)
                          const LinearProgressIndicator(),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ProgressSection(
                            summary: todaySummary,
                            periodKeys: todayPeriodKeys,
                            medicines: medicines,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ReminderCard(
                            medicines: medicines,
                            isUpdatingDose: isUpdatingDose,
                            onUpdateDose: updateDoseStatus,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: PatientMedicineListCard(
                            medicines: medicines,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: PatientActivityCard(
                            logs: logs,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          ConfettiWidget(
            confettiController: confettiController,
            numberOfParticles: 24,
            gravity: 0.18,
            shouldLoop: false,
          ),
        ],
      ),
    );
  }
}

class PatientDashboardHeader extends StatelessWidget {
  const PatientDashboardHeader({
    super.key,
    required this.patient,
    required this.onSignOutTap,
  });

  final Patient patient;
  final VoidCallback onSignOutTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2F80ED),
            Color(0xFF00C2D8),
          ],
        ),
      ),
      child: Row(
        children: [
          PatientHeaderPhoto(
            photoPath: patient.photoPath,
            photoUrl: patient.photoUrl,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PatientHeaderText(patient: patient),
          ),
          InkWell(
            onTap: onSignOutTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout,
                color: Color(0xFF2F80ED),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PatientHeaderPhoto extends StatelessWidget {
  const PatientHeaderPhoto({
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
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          photoUrl,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const PatientHeaderDefaultPhoto();
          },
        ),
      );
    }

    if (photoPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.file(
          File(photoPath),
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const PatientHeaderDefaultPhoto();
          },
        ),
      );
    }

    return const PatientHeaderDefaultPhoto();
  }
}

class PatientHeaderDefaultPhoto extends StatelessWidget {
  const PatientHeaderDefaultPhoto({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 36,
      ),
    );
  }
}

class PatientHeaderText extends StatelessWidget {
  const PatientHeaderText({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'রোগী ড্যাশবোর্ড',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          patient.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          patient.diseaseList.isEmpty
              ? 'সমস্যা উল্লেখ করা হয়নি'
              : patient.diseaseList,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class ProgressSection extends StatelessWidget {
  const ProgressSection({
    super.key,
    required this.summary,
    required this.periodKeys,
    required this.medicines,
  });

  final DoseSummary summary;
  final List<String> periodKeys;
  final List<MedicineEntry> medicines;

  @override
  Widget build(BuildContext context) {
    final total = summary.total;
    final progressValue = total == 0 ? 0.0 : summary.taken / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFB144F5),
            Color(0xFFFF2D8C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'আজকের অগ্রগতি',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${summary.taken}/$total ডোজ সম্পন্ন',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: Colors.white.withOpacity(0.35),
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ProgressMiniBox(
                  value: '${summary.pending}/$total',
                  label: 'Pending',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ProgressMiniBox(
                  value: '${summary.missed}/$total',
                  label: 'খায়নি',
                ),
              ),
            ],
          ),
          if (periodKeys.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: periodKeys.map((periodKey) {
                final periodSummary = helperPatientSummaryForPeriod(
                  medicines: medicines,
                  date: DateTime.now(),
                  periodKey: periodKey,
                );

                return PeriodProgressChip(
                  periodKey: periodKey,
                  summary: periodSummary,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class ProgressMiniBox extends StatelessWidget {
  const ProgressMiniBox({
    super.key,
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class PeriodProgressChip extends StatelessWidget {
  const PeriodProgressChip({
    super.key,
    required this.periodKey,
    required this.summary,
  });

  final String periodKey;
  final DoseSummary summary;

  @override
  Widget build(BuildContext context) {
    String status = '-';

    if (summary.isAllTaken) {
      status = '✓';
    } else if (summary.isAllMissed) {
      status = '✕';
    } else if (summary.isPartial) {
      status = '${summary.taken}/${summary.total}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${helperPeriodTitle(periodKey)} $status',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.medicines,
    required this.isUpdatingDose,
    required this.onUpdateDose,
  });

  final List<MedicineEntry> medicines;
  final bool isUpdatingDose;
  final Future<void> Function({
  required MedicineEntry medicine,
  required String periodKey,
  required String result,
  }) onUpdateDose;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final periodKeys = helperPatientScheduledPeriodsForDate(
      medicines: medicines,
      date: today,
    );

    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.12),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  size: 22,
                  color: Color(0xFF2F80ED),
                ),
                SizedBox(width: 8),
                Text(
                  'আজকের ওষুধ',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (periodKeys.isEmpty)
              const EmptyReminderView()
            else
              ...periodKeys.map((periodKey) {
                final periodMedicines = medicines.where((medicine) {
                  final summary = helperMedicineSummaryForPeriod(
                    medicine: medicine,
                    date: today,
                    periodKey: periodKey,
                  );

                  return summary.total > 0;
                }).toList();

                return PeriodReminderSection(
                  periodKey: periodKey,
                  medicines: periodMedicines,
                  isUpdatingDose: isUpdatingDose,
                  onUpdateDose: onUpdateDose,
                );
              }),
          ],
        ),
      ),
    );
  }
}

class EmptyReminderView extends StatelessWidget {
  const EmptyReminderView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          'আজ কোনো ওষুধ নির্ধারিত নেই',
          style: TextStyle(
            color: Color(0xFF667085),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class PeriodReminderSection extends StatelessWidget {
  const PeriodReminderSection({
    super.key,
    required this.periodKey,
    required this.medicines,
    required this.isUpdatingDose,
    required this.onUpdateDose,
  });

  final String periodKey;
  final List<MedicineEntry> medicines;
  final bool isUpdatingDose;
  final Future<void> Function({
  required MedicineEntry medicine,
  required String periodKey,
  required String result,
  }) onUpdateDose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            helperPeriodPossessive(periodKey),
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...medicines.map((medicine) {
            return ReminderMedicineTile(
              medicine: medicine,
              periodKey: periodKey,
              isUpdatingDose: isUpdatingDose,
              onUpdateDose: onUpdateDose,
            );
          }),
        ],
      ),
    );
  }
}

class ReminderMedicineTile extends StatelessWidget {
  const ReminderMedicineTile({
    super.key,
    required this.medicine,
    required this.periodKey,
    required this.isUpdatingDose,
    required this.onUpdateDose,
  });

  final MedicineEntry medicine;
  final String periodKey;
  final bool isUpdatingDose;
  final Future<void> Function({
  required MedicineEntry medicine,
  required String periodKey,
  required String result,
  }) onUpdateDose;

  @override
  Widget build(BuildContext context) {
    final summary = helperMedicineSummaryForPeriod(
      medicine: medicine,
      date: DateTime.now(),
      periodKey: periodKey,
    );

    final isTaken = summary.taken > 0;
    final isMissed = summary.missed > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE4E7EC),
        ),
      ),
      child: Row(
        children: [
          MedicinePhoto(
            imagePath: medicine.imagePath,
            imageUrl: medicine.imageUrl,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ReminderMedicineInfo(
              medicine: medicine,
              isTaken: isTaken,
              isMissed: isMissed,
            ),
          ),
          Column(
            children: [
              DoseActionButton(
                label: 'খেয়েছি',
                icon: Icons.check,
                color: const Color(0xFF16A34A),
                isSelected: isTaken,
                isDisabled: isUpdatingDose,
                onTap: () {
                  onUpdateDose(
                    medicine: medicine,
                    periodKey: periodKey,
                    result: 'taken',
                  );
                },
              ),
              const SizedBox(height: 6),
              DoseActionButton(
                label: 'খাইনি',
                icon: Icons.close,
                color: const Color(0xFFDC2626),
                isSelected: isMissed,
                isDisabled: isUpdatingDose,
                onTap: () {
                  onUpdateDose(
                    medicine: medicine,
                    periodKey: periodKey,
                    result: 'missed',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReminderMedicineInfo extends StatelessWidget {
  const ReminderMedicineInfo({
    super.key,
    required this.medicine,
    required this.isTaken,
    required this.isMissed,
  });

  final MedicineEntry medicine;
  final bool isTaken;
  final bool isMissed;

  @override
  Widget build(BuildContext context) {
    String statusText = 'Pending';
    Color statusColor = const Color(0xFFEA580C);
    Color statusBackground = const Color(0xFFFFF4E5);

    if (isTaken) {
      statusText = 'খেয়েছে';
      statusColor = const Color(0xFF16A34A);
      statusBackground = const Color(0xFFEFFAF2);
    } else if (isMissed) {
      statusText = 'খায়নি';
      statusColor = const Color(0xFFDC2626);
      statusBackground = const Color(0xFFFFF1F1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          medicine.name,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (medicine.instruction.isNotEmpty)
          Text(
            medicine.instruction,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: statusBackground,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class DoseActionButton extends StatelessWidget {
  const DoseActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: OutlinedButton.icon(
        onPressed: isDisabled ? null : onTap,
        icon: Icon(
          icon,
          size: 14,
          color: isSelected ? Colors.white : color,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: BorderSide(color: color),
          backgroundColor: isSelected ? color : Colors.white,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class PatientMedicineListCard extends StatelessWidget {
  const PatientMedicineListCard({
    super.key,
    required this.medicines,
  });

  final List<MedicineEntry> medicines;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.12),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(
                  Icons.medication_liquid,
                  size: 22,
                  color: Color(0xFFB144F5),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'আমার ওষুধের তালিকা',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (medicines.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'কোনো ওষুধ যোগ করা হয়নি',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 14,
                  ),
                ),
              )
            else
              ...medicines.map(
                    (medicine) => PatientMedicineTile(medicine: medicine),
              ),
          ],
        ),
      ),
    );
  }
}

class PatientMedicineTile extends StatelessWidget {
  const PatientMedicineTile({
    super.key,
    required this.medicine,
  });

  final MedicineEntry medicine;

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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE4E7EC),
        ),
      ),
      child: Row(
        children: [
          MedicinePhoto(
            imagePath: medicine.imagePath,
            imageUrl: medicine.imageUrl,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (medicine.instruction.isNotEmpty)
                  Text(
                    medicine.instruction,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
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
                        color: const Color(0xFF2F80ED),
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
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'আজ: ${todaySummary.taken}/${todaySummary.total}',
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      'বাকি: $remainingDays দিন',
                      style: const TextStyle(
                        color: Color(0xFFEA580C),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progressValue.clamp(0.0, 1.0),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(10),
                  backgroundColor: const Color(0xFFE5E7EB),
                  color: const Color(0xFF16A34A),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MedicinePhoto extends StatelessWidget {
  const MedicinePhoto({
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
        borderRadius: BorderRadius.circular(13),
        child: Image.network(
          imageUrl,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const DefaultMedicinePhoto();
          },
        ),
      );
    }

    if (imagePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.file(
          File(imagePath),
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const DefaultMedicinePhoto();
          },
        ),
      );
    }

    return const DefaultMedicinePhoto();
  }
}

class DefaultMedicinePhoto extends StatelessWidget {
  const DefaultMedicinePhoto({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(
        Icons.medication_liquid,
        color: Color(0xFFB144F5),
        size: 30,
      ),
    );
  }
}

class PatientActivityCard extends StatelessWidget {
  const PatientActivityCard({
    super.key,
    required this.logs,
  });

  final List<PatientActivityLog> logs;

  @override
  Widget build(BuildContext context) {
    final recentLogs = logs.take(5).toList();

    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.12),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.history,
                  size: 22,
                  color: Color(0xFF2F80ED),
                ),
                SizedBox(width: 8),
                Text(
                  'সাম্প্রতিক কার্যকলাপ',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentLogs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'এখনো কোনো কার্যকলাপ নেই',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              ...recentLogs.map((log) {
                final isTaken = log.status == 'খেয়েছে';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE4E7EC),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isTaken ? Icons.check_circle : Icons.cancel,
                        color: isTaken
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${log.periodName}: ${log.medicineName} ${log.status}',
                          style: TextStyle(
                            color: isTaken
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        helperFormatActivityTime(log.time),
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 11,
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