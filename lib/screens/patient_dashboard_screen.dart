import 'dart:io';

import 'package:flutter/material.dart';

import '../models/patient_model.dart';

enum DayPeriod {
  morning,
  afternoon,
  night,
}

String periodKey(DayPeriod period) {
  switch (period) {
    case DayPeriod.morning:
      return 'morning';
    case DayPeriod.afternoon:
      return 'afternoon';
    case DayPeriod.night:
      return 'night';
  }
}

String periodTitle(DayPeriod period) {
  switch (period) {
    case DayPeriod.morning:
      return 'সকাল';
    case DayPeriod.afternoon:
      return 'দুপুর';
    case DayPeriod.night:
      return 'রাত';
  }
}

DayPeriod periodFromTimeText(String timeText) {
  final lowerText = timeText.toLowerCase();
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeText);

  if (match == null) {
    return DayPeriod.morning;
  }

  int hour = int.tryParse(match.group(1) ?? '0') ?? 0;

  if (lowerText.contains('pm') && hour != 12) {
    hour += 12;
  }

  if (lowerText.contains('am') && hour == 12) {
    hour = 0;
  }

  if (hour >= 5 && hour < 12) {
    return DayPeriod.morning;
  } else if (hour >= 12 && hour < 18) {
    return DayPeriod.afternoon;
  } else {
    return DayPeriod.night;
  }
}

List<DayPeriod> getScheduledPeriods(Patient patient) {
  final periods = <DayPeriod>{};

  for (final medicine in patient.medicines) {
    for (final time in medicine.times) {
      periods.add(periodFromTimeText(time));
    }
  }

  const orderedPeriods = [
    DayPeriod.morning,
    DayPeriod.afternoon,
    DayPeriod.night,
  ];

  return orderedPeriods.where(periods.contains).toList();
}

List<DayPeriod> getMedicinePeriods(MedicineEntry medicine) {
  final periods = <DayPeriod>{};

  for (final time in medicine.times) {
    periods.add(periodFromTimeText(time));
  }

  const orderedPeriods = [
    DayPeriod.morning,
    DayPeriod.afternoon,
    DayPeriod.night,
  ];

  return orderedPeriods.where(periods.contains).toList();
}

bool isMedicineScheduledInPeriod(MedicineEntry medicine, DayPeriod period) {
  return medicine.times.any((time) => periodFromTimeText(time) == period);
}

bool isMedicineTakenInPeriod(MedicineEntry medicine, DayPeriod period) {
  return medicine.takenPeriodKeys.contains(periodKey(period));
}

bool isMedicineMissedInPeriod(MedicineEntry medicine, DayPeriod period) {
  return medicine.missedPeriodKeys.contains(periodKey(period));
}

bool isPeriodCompleted(Patient patient, DayPeriod period) {
  final periodMedicines = patient.medicines.where((medicine) {
    return isMedicineScheduledInPeriod(medicine, period);
  }).toList();

  if (periodMedicines.isEmpty) return false;

  return periodMedicines.every((medicine) {
    return isMedicineTakenInPeriod(medicine, period);
  });
}

bool isMedicineFullyTakenToday(MedicineEntry medicine) {
  final periods = getMedicinePeriods(medicine);

  if (periods.isEmpty) return false;

  return periods.every((period) {
    return medicine.takenPeriodKeys.contains(periodKey(period));
  });
}

bool isMedicinePartlyMissedToday(MedicineEntry medicine) {
  return medicine.missedPeriodKeys.isNotEmpty;
}

class MedicineReminderTarget {
  MedicineReminderTarget({
    required this.medicine,
    required this.period,
  });

  final MedicineEntry medicine;
  final DayPeriod period;
}

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
  List<DayPeriod> get todayPeriods {
    return getScheduledPeriods(widget.patient);
  }

  int get completedTaskCount {
    return todayPeriods
        .where((period) => isPeriodCompleted(widget.patient, period))
        .length;
  }

  int get totalTaskCount {
    return todayPeriods.length;
  }

  void showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) {
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
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void refreshDashboard() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            PatientDashboardHeader(
              patient: patient,
              onSignOutTap: showSignOutDialog,
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProgressSection(
                todayPeriods: todayPeriods,
                completedTaskCount: completedTaskCount,
                totalTaskCount: totalTaskCount,
                patient: patient,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ReminderCard(
                patient: patient,
                onChanged: refreshDashboard,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MedicineListCard(patient: patient),
            ),
            const SizedBox(height: 24),
          ],
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
          PatientHeaderPhoto(photoPath: patient.photoPath),
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
  });

  final String photoPath;

  @override
  Widget build(BuildContext context) {
    if (photoPath.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person,
          color: Color(0xFF2F80ED),
          size: 30,
        ),
      );
    }

    return ClipOval(
      child: Image.file(
        File(photoPath),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
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
        Text(
          patient.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'বয়স: ${patient.age} বছর',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        if (patient.diseaseList.isNotEmpty)
          Text(
            patient.diseaseList,
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
    required this.todayPeriods,
    required this.completedTaskCount,
    required this.totalTaskCount,
    required this.patient,
  });

  final List<DayPeriod> todayPeriods;
  final int completedTaskCount;
  final int totalTaskCount;
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final progressText =
    totalTaskCount == 0 ? '0/0' : '$completedTaskCount/$totalTaskCount';

    return Container(
      padding: const EdgeInsets.all(14),
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
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'আজকের অগ্রগতি',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  progressText,
                  style: const TextStyle(
                    color: Color(0xFFB144F5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (todayPeriods.isEmpty)
            const Text(
              'আজ কোনো ওষুধের সময় নির্ধারিত নেই',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            )
          else
            Row(
              children: [
                for (int i = 0; i < todayPeriods.length; i++) ...[
                  Expanded(
                    child: ProgressBox(
                      title: periodTitle(todayPeriods[i]),
                      isCompleted: isPeriodCompleted(
                        patient,
                        todayPeriods[i],
                      ),
                    ),
                  ),
                  if (i != todayPeriods.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class ProgressBox extends StatelessWidget {
  const ProgressBox({
    super.key,
    required this.title,
    required this.isCompleted,
  });

  final String title;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isCompleted
          ? const Center(
        child: Icon(
          Icons.check_circle,
          color: Color(0xFF22C55E),
          size: 46,
        ),
      )
          : Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFB144F5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.patient,
    required this.onChanged,
  });

  final Patient patient;
  final VoidCallback onChanged;

  MedicineReminderTarget? get firstPendingDose {
    final periods = getScheduledPeriods(patient);

    for (final period in periods) {
      for (final medicine in patient.medicines) {
        final isScheduled = isMedicineScheduledInPeriod(medicine, period);
        final isTaken = isMedicineTakenInPeriod(medicine, period);
        final isMissed = isMedicineMissedInPeriod(medicine, period);

        if (isScheduled && !isTaken && !isMissed) {
          return MedicineReminderTarget(
            medicine: medicine,
            period: period,
          );
        }
      }
    }

    if (patient.medicines.isNotEmpty) {
      final medicine = patient.medicines.first;
      final medicinePeriods = getMedicinePeriods(medicine);

      if (medicinePeriods.isNotEmpty) {
        return MedicineReminderTarget(
          medicine: medicine,
          period: medicinePeriods.first,
        );
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final MedicineReminderTarget? target = firstPendingDose;

    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.medication_outlined,
              size: 70,
              color: Color(0xFFD0D5DD),
            ),
            const SizedBox(height: 10),
            const Text(
              'কোনো রিমাইন্ডার নেই',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'নির্ধারিত সময়ে ওষুধের রিমাইন্ডার আসবে',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF667085),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (target == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('এখনো কোনো ওষুধ যোগ করা হয়নি'),
                      ),
                    );
                    return;
                  }

                  final String? result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicineReminderDemoScreen(
                        medicine: target.medicine,
                        period: target.period,
                      ),
                    ),
                  );

                  if (result == 'taken') {
                    final key = periodKey(target.period);

                    target.medicine.takenPeriodKeys.add(key);
                    target.medicine.missedPeriodKeys.remove(key);

                    target.medicine.isTakenToday =
                        isMedicineFullyTakenToday(target.medicine);
                    target.medicine.isMissedToday =
                        isMedicinePartlyMissedToday(target.medicine);
                    patient.activityLogs.insert(
                      0,
                      PatientActivityLog(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        medicineName: target.medicine.name,
                        periodName: periodTitle(target.period),
                        status: 'খেয়েছে',
                        time: DateTime.now(),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${periodTitle(target.period)} এর ওষুধ খেয়েছেন হিসেবে সংরক্ষণ হয়েছে',
                        ),
                      ),
                    );
                    onChanged();
                  }

                  if (result == 'missed') {
                    final key = periodKey(target.period);

                    target.medicine.missedPeriodKeys.add(key);
                    target.medicine.takenPeriodKeys.remove(key);

                    target.medicine.isTakenToday =
                        isMedicineFullyTakenToday(target.medicine);
                    target.medicine.isMissedToday =
                        isMedicinePartlyMissedToday(target.medicine);
                    patient.activityLogs.insert(
                      0,
                      PatientActivityLog(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        medicineName: target.medicine.name,
                        periodName: periodTitle(target.period),
                        status: 'খায়নি',
                        time: DateTime.now(),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${periodTitle(target.period)} এর ওষুধ খাইনি হিসেবে সংরক্ষণ হয়েছে',
                        ),
                      ),
                    );

                    onChanged();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2F80ED),
                        Color(0xFFB144F5),
                      ],
                    ),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'টেস্ট রিমাইন্ডার দেখুন',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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

class MedicineListCard extends StatelessWidget {
  const MedicineListCard({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'আমার ওষুধসমূহ',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (patient.medicines.isEmpty)
              const Text(
                'এখনো কোনো ওষুধ নেই',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 14,
                ),
              )
            else
              ...patient.medicines.map(
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
    final statusText = medicine.isTakenToday
        ? 'Complete'
        : medicine.isMissedToday
        ? 'Missed'
        : 'Ongoing';

    final statusColor = medicine.isTakenToday
        ? const Color(0xFF16A34A)
        : medicine.isMissedToday
        ? const Color(0xFFDC2626)
        : const Color(0xFF16A34A);

    final statusBackground = medicine.isTakenToday
        ? const Color(0xFFEFFAF2)
        : medicine.isMissedToday
        ? const Color(0xFFFFF1F1)
        : const Color(0xFFEFFAF2);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          MedicinePhoto(imagePath: medicine.imagePath),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (medicine.instruction.isNotEmpty)
                  Text(
                    medicine.instruction,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475467),
                    ),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: medicine.times.map((time) {
                    final period = periodFromTimeText(time);
                    final key = periodKey(period);
                    final isTaken = medicine.takenPeriodKeys.contains(key);
                    final isMissed = medicine.missedPeriodKeys.contains(key);

                    Color timeColor = const Color(0xFF2F80ED);
                    if (isTaken) {
                      timeColor = const Color(0xFF16A34A);
                    } else if (isMissed) {
                      timeColor = const Color(0xFFDC2626);
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: timeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        time,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MedicineReminderDemoScreen extends StatelessWidget {
  const MedicineReminderDemoScreen({
    super.key,
    required this.medicine,
    required this.period,
  });

  final MedicineEntry medicine;
  final DayPeriod period;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(18),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFF2F80ED),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MedicineLargePhoto(imagePath: medicine.imagePath),
                const SizedBox(height: 16),
                Text(
                  '${periodTitle(period)}ের ওষুধ খাওয়ার সময় হয়েছে',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF344054),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (medicine.instruction.isNotEmpty)
                  Text(
                    medicine.instruction,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF667085),
                    ),
                  ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: ReminderActionButton(
                        label: 'খেয়েছি',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF22C55E),
                        onTap: () {
                          Navigator.pop(context, 'taken');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ReminderActionButton(
                        label: 'খাইনি',
                        icon: Icons.close,
                        color: const Color(0xFFEF4444),
                        onTap: () {
                          Navigator.pop(context, 'missed');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReminderActionButton extends StatelessWidget {
  const ReminderActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 34,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MedicinePhoto extends StatelessWidget {
  const MedicinePhoto({
    super.key,
    required this.imagePath,
  });

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.medication_liquid,
          color: Color(0xFFB144F5),
          size: 30,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(imagePath),
        width: 58,
        height: 58,
        fit: BoxFit.cover,
      ),
    );
  }
}

class MedicineLargePhoto extends StatelessWidget {
  const MedicineLargePhoto({
    super.key,
    required this.imagePath,
  });

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return Container(
        width: double.infinity,
        height: 175,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.medication_liquid,
          color: Color(0xFFB144F5),
          size: 70,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.file(
        File(imagePath),
        width: double.infinity,
        height: 175,
        fit: BoxFit.cover,
      ),
    );
  }
}