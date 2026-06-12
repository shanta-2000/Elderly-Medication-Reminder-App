import 'dart:io';

import 'package:flutter/material.dart';

import '../models/patient_model.dart';

enum DayPeriod {
  morning,
  afternoon,
  night,
}

String twoDigit(int value) {
  return value.toString().padLeft(2, '0');
}

String dateKey(DateTime date) {
  final cleanDate = dateOnly(date);
  return '${cleanDate.year}-${twoDigit(cleanDate.month)}-${twoDigit(cleanDate.day)}';
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

String doseKey(DateTime date, DayPeriod period) {
  return '${dateKey(date)}_${periodKey(period)}';
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

String periodPossessive(DayPeriod period) {
  switch (period) {
    case DayPeriod.morning:
      return 'সকালের';
    case DayPeriod.afternoon:
      return 'দুপুরের';
    case DayPeriod.night:
      return 'রাতের';
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

String formatShortDate(DateTime date) {
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

  return '${date.day} ${months[date.month - 1]}';
}

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

List<DateTime> getMedicineDates(MedicineEntry medicine) {
  final dates = <DateTime>[];
  DateTime currentDate = dateOnly(medicine.startDate);
  final endDate = dateOnly(medicine.endDate);

  while (!currentDate.isAfter(endDate)) {
    dates.add(currentDate);
    currentDate = currentDate.add(const Duration(days: 1));
  }

  return dates;
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

bool isMedicineActiveOnDate(MedicineEntry medicine, DateTime date) {
  final cleanDate = dateOnly(date);
  final start = dateOnly(medicine.startDate);
  final end = dateOnly(medicine.endDate);

  return !cleanDate.isBefore(start) && !cleanDate.isAfter(end);
}

bool isDoseTaken(MedicineEntry medicine, DateTime date, DayPeriod period) {
  return medicine.takenDoseKeys.contains(doseKey(date, period));
}

bool isDoseMissed(MedicineEntry medicine, DateTime date, DayPeriod period) {
  return medicine.missedDoseKeys.contains(doseKey(date, period));
}

List<DayPeriod> getTodayScheduledPeriods(Patient patient) {
  final today = dateOnly(DateTime.now());
  final periods = <DayPeriod>{};

  for (final medicine in patient.medicines) {
    if (!isMedicineActiveOnDate(medicine, today)) continue;

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

bool isPeriodCompletedToday(Patient patient, DayPeriod period) {
  final today = dateOnly(DateTime.now());

  final periodMedicines = patient.medicines.where((medicine) {
    return isMedicineActiveOnDate(medicine, today) &&
        isMedicineScheduledInPeriod(medicine, period);
  }).toList();

  if (periodMedicines.isEmpty) return false;

  return periodMedicines.every((medicine) {
    return isDoseTaken(medicine, today, period);
  });
}

bool isMedicineDayTaken(MedicineEntry medicine, DateTime date) {
  if (!isMedicineActiveOnDate(medicine, date)) return false;

  final periods = getMedicinePeriods(medicine);

  if (periods.isEmpty) return false;

  return periods.every((period) {
    return isDoseTaken(medicine, date, period);
  });
}

bool isMedicineDayMissed(MedicineEntry medicine, DateTime date) {
  if (!isMedicineActiveOnDate(medicine, date)) return false;

  final periods = getMedicinePeriods(medicine);

  return periods.any((period) {
    return isDoseMissed(medicine, date, period);
  });
}

int takenDaysCount(MedicineEntry medicine) {
  return getMedicineDates(medicine).where((date) {
    return isMedicineDayTaken(medicine, date);
  }).length;
}

void updateMedicineTodayStatus(MedicineEntry medicine) {
  final today = dateOnly(DateTime.now());

  if (!isMedicineActiveOnDate(medicine, today)) {
    medicine.isTakenToday = false;
    medicine.isMissedToday = false;
    return;
  }

  final periods = getMedicinePeriods(medicine);

  medicine.isTakenToday = periods.isNotEmpty &&
      periods.every((period) {
        return isDoseTaken(medicine, today, period);
      });

  medicine.isMissedToday = periods.any((period) {
    return isDoseMissed(medicine, today, period);
  });
}

class MedicineReminderTarget {
  MedicineReminderTarget({
    required this.medicine,
    required this.period,
    required this.date,
  });

  final MedicineEntry medicine;
  final DayPeriod period;
  final DateTime date;
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
    return getTodayScheduledPeriods(widget.patient);
  }

  int get completedTaskCount {
    return todayPeriods
        .where((period) => isPeriodCompletedToday(widget.patient, period))
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
              'আজ কোনো চলমান ওষুধের সময় নেই',
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
                      isCompleted: isPeriodCompletedToday(
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
    final today = dateOnly(DateTime.now());
    final periods = getTodayScheduledPeriods(patient);

    for (final period in periods) {
      for (final medicine in patient.medicines) {
        final isScheduled = isMedicineScheduledInPeriod(medicine, period);
        final isActive = isMedicineActiveOnDate(medicine, today);
        final taken = isDoseTaken(medicine, today, period);
        final missed = isDoseMissed(medicine, today, period);

        if (isActive && isScheduled && !taken && !missed) {
          return MedicineReminderTarget(
            medicine: medicine,
            period: period,
            date: today,
          );
        }
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
            Icon(
              target == null
                  ? Icons.check_circle_outline
                  : Icons.medication_outlined,
              size: 70,
              color: target == null
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFD0D5DD),
            ),
            const SizedBox(height: 10),
            Text(
              target == null
                  ? 'আজকের সব রিমাইন্ডার শেষ'
                  : '${periodPossessive(target.period)} রিমাইন্ডার',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              target == null
                  ? 'চলমান ওষুধের আজ আর কোনো pending dose নেই'
                  : '${target.medicine.name} খাওয়ার সময় হয়েছে',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: target == null
                    ? null
                    : () async {
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
                    final key = doseKey(target.date, target.period);

                    target.medicine.takenDoseKeys.add(key);
                    target.medicine.missedDoseKeys.remove(key);

                    updateMedicineTodayStatus(target.medicine);

                    patient.activityLogs.insert(
                      0,
                      PatientActivityLog(
                        id: DateTime.now()
                            .millisecondsSinceEpoch
                            .toString(),
                        medicineName: target.medicine.name,
                        periodName: periodTitle(target.period),
                        status: 'খেয়েছে',
                        time: DateTime.now(),
                        date: dateOnly(DateTime.now()),
                      ),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${periodPossessive(target.period)} ${target.medicine.name} খেয়েছেন হিসেবে সংরক্ষণ হয়েছে',
                        ),
                      ),
                    );

                    onChanged();
                  }

                  if (result == 'missed') {
                    final key = doseKey(target.date, target.period);

                    target.medicine.missedDoseKeys.add(key);
                    target.medicine.takenDoseKeys.remove(key);

                    updateMedicineTodayStatus(target.medicine);

                    patient.activityLogs.insert(
                      0,
                      PatientActivityLog(
                        id: DateTime.now()
                            .millisecondsSinceEpoch
                            .toString(),
                        medicineName: target.medicine.name,
                        periodName: periodTitle(target.period),
                        status: 'খায়নি',
                        time: DateTime.now(),
                        date: dateOnly(DateTime.now()),
                      ),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${periodPossessive(target.period)} ${target.medicine.name} খাইনি হিসেবে সংরক্ষণ হয়েছে',
                        ),
                      ),
                    );

                    onChanged();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor:
                  target == null ? Colors.grey.shade300 : Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: target == null
                        ? null
                        : const LinearGradient(
                      colors: [
                        Color(0xFF2F80ED),
                        Color(0xFFB144F5),
                      ],
                    ),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      target == null
                          ? 'আজ আর রিমাইন্ডার নেই'
                          : 'টেস্ট রিমাইন্ডার দেখুন',
                      style: TextStyle(
                        color: target == null
                            ? const Color(0xFF667085)
                            : Colors.white,
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
    final takenDays = takenDaysCount(medicine);
    final totalDays = medicine.totalDays;

    int remainingDays = totalDays - takenDays;
    if (remainingDays < 0) {
      remainingDays = 0;
    }

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
              MedicinePhoto(imagePath: medicine.imagePath),
              const SizedBox(width: 10),
              Expanded(
                child: MedicineMainInfo(
                  medicine: medicine,
                  statusColor: statusColor,
                  statusBackground: statusBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MedicineDateInfoRow(medicine: medicine),
          const SizedBox(height: 10),
          MedicineDaysSummary(
            takenDays: takenDays,
            remainingDays: remainingDays,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
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
              fontSize: 12,
              color: Color(0xFF475467),
            ),
          ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 5,
          children: medicine.times.map((time) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2F80ED),
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
      ],
    );
  }
}

class MedicineDateInfoRow extends StatelessWidget {
  const MedicineDateInfoRow({
    super.key,
    required this.medicine,
  });

  final MedicineEntry medicine;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SmallInfoText(
            title: 'শুরু',
            value: formatShortDate(medicine.startDate),
          ),
        ),
        Expanded(
          child: SmallInfoText(
            title: 'শেষ',
            value: formatShortDate(medicine.endDate),
          ),
        ),
        Expanded(
          child: SmallInfoText(
            title: 'সময়কাল',
            value: '${medicine.totalDays} দিন',
          ),
        ),
      ],
    );
  }
}

class SmallInfoText extends StatelessWidget {
  const SmallInfoText({
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

class MedicineDaysSummary extends StatelessWidget {
  const MedicineDaysSummary({
    super.key,
    required this.takenDays,
    required this.remainingDays,
  });

  final int takenDays;
  final int remainingDays;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DaySummaryBox(
            title: 'খাওয়া হয়েছে',
            value: '$takenDays দিন',
            backgroundColor: const Color(0xFFEFFAF2),
            textColor: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DaySummaryBox(
            title: 'বাকি',
            value: '$remainingDays দিন',
            backgroundColor: const Color(0xFFFFF4E5),
            textColor: const Color(0xFFEA580C),
          ),
        ),
      ],
    );
  }
}

class DaySummaryBox extends StatelessWidget {
  const DaySummaryBox({
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
    final dates = getMedicineDates(medicine);

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
    final isTaken = isMedicineDayTaken(medicine, date);
    final isMissed = isMedicineDayMissed(medicine, date);

    IconData icon = Icons.remove;
    Color iconColor = const Color(0xFF667085);
    Color backgroundColor = Colors.white;
    Color borderColor = const Color(0xFFE4E7EC);

    if (isTaken) {
      icon = Icons.check_circle;
      iconColor = const Color(0xFF16A34A);
      backgroundColor = const Color(0xFFEFFAF2);
      borderColor = const Color(0xFFBBF7D0);
    } else if (isMissed) {
      icon = Icons.cancel;
      iconColor = const Color(0xFFDC2626);
      backgroundColor = const Color(0xFFFFF1F1);
      borderColor = const Color(0xFFFECACA);
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
            formatShortDate(date),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF344054),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Icon(
            icon,
            color: iconColor,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class PatientActivityCard extends StatelessWidget {
  const PatientActivityCard({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final logs = patient.activityLogs.take(5).toList();

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
              'সাম্প্রতিক কার্যকলাপ',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'এখনো কোনো কার্যকলাপ নেই',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              ...logs.map((log) {
                final isTaken = log.status == 'খেয়েছে';

                return Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isTaken
                        ? const Color(0xFFEFFAF2)
                        : const Color(0xFFFFF1F1),
                    borderRadius: BorderRadius.circular(11),
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
                        size: 24,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '${formatShortDate(log.date)}, ${log.periodName} - ${log.medicineName} ${log.status}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        formatActivityTime(log.time),
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
                  '${periodPossessive(period)} ওষুধ খাওয়ার সময় হয়েছে',
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