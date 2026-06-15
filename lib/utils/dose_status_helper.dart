import '../models/patient_model.dart';

class DoseSummary {
  const DoseSummary({
    required this.total,
    required this.taken,
    required this.missed,
    required this.pending,
  });

  final int total;
  final int taken;
  final int missed;
  final int pending;

  bool get hasNoDose => total == 0;
  bool get isAllPending => total > 0 && taken == 0 && missed == 0;
  bool get isAllTaken => total > 0 && taken == total;
  bool get isAllMissed => total > 0 && missed == total;
  bool get isPartial => total > 0 && !isAllTaken && !isAllMissed && !isAllPending;

  String get takenFraction => '$taken/$total';
  String get missedFraction => '$missed/$total';
  String get pendingFraction => '$pending/$total';
}

String helperTwoDigit(int value) {
  return value.toString().padLeft(2, '0');
}

String helperDateKey(DateTime date) {
  final cleanDate = dateOnly(date);
  return '${cleanDate.year}-${helperTwoDigit(cleanDate.month)}-${helperTwoDigit(cleanDate.day)}';
}

String helperDoseKey(DateTime date, String periodKey) {
  return '${helperDateKey(date)}_$periodKey';
}

String helperPeriodKeyFromTimeText(String timeText) {
  final lowerText = timeText.toLowerCase();
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeText);

  if (match == null) return 'morning';

  int hour = int.tryParse(match.group(1) ?? '0') ?? 0;

  if (lowerText.contains('pm') && hour != 12) {
    hour += 12;
  }

  if (lowerText.contains('am') && hour == 12) {
    hour = 0;
  }

  if (hour >= 5 && hour < 12) {
    return 'morning';
  } else if (hour >= 12 && hour < 18) {
    return 'afternoon';
  } else {
    return 'night';
  }
}

String helperPeriodTitle(String periodKey) {
  switch (periodKey) {
    case 'morning':
      return 'সকাল';
    case 'afternoon':
      return 'দুপুর';
    case 'night':
      return 'রাত';
    default:
      return periodKey;
  }
}

String helperPeriodPossessive(String periodKey) {
  switch (periodKey) {
    case 'morning':
      return 'সকালের';
    case 'afternoon':
      return 'দুপুরের';
    case 'night':
      return 'রাতের';
    default:
      return periodKey;
  }
}

String helperFormatShortDate(DateTime date) {
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

String helperFormatFullDate(DateTime date) {
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

String helperFormatActivityTime(DateTime time) {
  final hour = time.hour > 12
      ? time.hour - 12
      : time.hour == 0
      ? 12
      : time.hour;

  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'PM' : 'AM';

  return '$hour:$minute $period';
}

List<String> helperMedicinePeriodKeys(MedicineEntry medicine) {
  final keys = <String>{};

  for (final time in medicine.times) {
    keys.add(helperPeriodKeyFromTimeText(time));
  }

  const orderedKeys = ['morning', 'afternoon', 'night'];

  return orderedKeys.where(keys.contains).toList();
}

bool helperIsMedicineActiveOnDate(MedicineEntry medicine, DateTime date) {
  final cleanDate = dateOnly(date);
  final start = dateOnly(medicine.startDate);
  final end = dateOnly(medicine.endDate);

  return !cleanDate.isBefore(start) && !cleanDate.isAfter(end);
}

List<DateTime> helperMedicineDates(MedicineEntry medicine) {
  final dates = <DateTime>[];
  DateTime currentDate = dateOnly(medicine.startDate);
  final endDate = dateOnly(medicine.endDate);

  while (!currentDate.isAfter(endDate)) {
    dates.add(currentDate);
    currentDate = currentDate.add(const Duration(days: 1));
  }

  return dates;
}

DoseSummary helperMedicineSummaryForDate({
  required MedicineEntry medicine,
  required DateTime date,
}) {
  if (!helperIsMedicineActiveOnDate(medicine, date)) {
    return const DoseSummary(
      total: 0,
      taken: 0,
      missed: 0,
      pending: 0,
    );
  }

  final periodKeys = helperMedicinePeriodKeys(medicine);

  int total = 0;
  int taken = 0;
  int missed = 0;

  for (final periodKey in periodKeys) {
    total++;

    final key = helperDoseKey(date, periodKey);

    if (medicine.takenDoseKeys.contains(key)) {
      taken++;
    } else if (medicine.missedDoseKeys.contains(key)) {
      missed++;
    }
  }

  int pending = total - taken - missed;
  if (pending < 0) pending = 0;

  return DoseSummary(
    total: total,
    taken: taken,
    missed: missed,
    pending: pending,
  );
}

DoseSummary helperMedicineSummaryForPeriod({
  required MedicineEntry medicine,
  required DateTime date,
  required String periodKey,
}) {
  if (!helperIsMedicineActiveOnDate(medicine, date)) {
    return const DoseSummary(
      total: 0,
      taken: 0,
      missed: 0,
      pending: 0,
    );
  }

  final periodKeys = helperMedicinePeriodKeys(medicine);

  if (!periodKeys.contains(periodKey)) {
    return const DoseSummary(
      total: 0,
      taken: 0,
      missed: 0,
      pending: 0,
    );
  }

  final key = helperDoseKey(date, periodKey);

  final isTaken = medicine.takenDoseKeys.contains(key);
  final isMissed = medicine.missedDoseKeys.contains(key);

  return DoseSummary(
    total: 1,
    taken: isTaken ? 1 : 0,
    missed: isMissed ? 1 : 0,
    pending: (!isTaken && !isMissed) ? 1 : 0,
  );
}

DoseSummary helperPatientSummaryForDate({
  required List<MedicineEntry> medicines,
  required DateTime date,
}) {
  int total = 0;
  int taken = 0;
  int missed = 0;
  int pending = 0;

  for (final medicine in medicines) {
    final summary = helperMedicineSummaryForDate(
      medicine: medicine,
      date: date,
    );

    total += summary.total;
    taken += summary.taken;
    missed += summary.missed;
    pending += summary.pending;
  }

  return DoseSummary(
    total: total,
    taken: taken,
    missed: missed,
    pending: pending,
  );
}

DoseSummary helperPatientSummaryForPeriod({
  required List<MedicineEntry> medicines,
  required DateTime date,
  required String periodKey,
}) {
  int total = 0;
  int taken = 0;
  int missed = 0;
  int pending = 0;

  for (final medicine in medicines) {
    final summary = helperMedicineSummaryForPeriod(
      medicine: medicine,
      date: date,
      periodKey: periodKey,
    );

    total += summary.total;
    taken += summary.taken;
    missed += summary.missed;
    pending += summary.pending;
  }

  return DoseSummary(
    total: total,
    taken: taken,
    missed: missed,
    pending: pending,
  );
}

List<String> helperPatientScheduledPeriodsForDate({
  required List<MedicineEntry> medicines,
  required DateTime date,
}) {
  final keys = <String>{};

  for (final medicine in medicines) {
    if (!helperIsMedicineActiveOnDate(medicine, date)) continue;

    keys.addAll(helperMedicinePeriodKeys(medicine));
  }

  const orderedKeys = ['morning', 'afternoon', 'night'];

  return orderedKeys.where(keys.contains).toList();
}

int helperMedicineTakenDaysCount(MedicineEntry medicine) {
  return helperMedicineDates(medicine).where((date) {
    final summary = helperMedicineSummaryForDate(
      medicine: medicine,
      date: date,
    );

    return summary.isAllTaken;
  }).length;
}

int helperMedicineRemainingDaysCount(MedicineEntry medicine) {
  final remaining = medicine.totalDays - helperMedicineTakenDaysCount(medicine);

  if (remaining < 0) return 0;

  return remaining;
}

String helperSmallStatusText(DoseSummary summary) {
  if (summary.hasNoDose) return '-';
  if (summary.isAllPending) return '-';
  if (summary.isAllTaken) return '✓';
  if (summary.isAllMissed) return '✕';

  return '${summary.taken}/${summary.total}';
}