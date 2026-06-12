DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

class Patient {
  Patient({
    required this.id,
    required this.userId,
    required this.password,
    required this.name,
    required this.age,
    required this.photoPath,
    required this.diseaseList,
    List<MedicineEntry>? medicines,
    List<PatientActivityLog>? activityLogs,
  })  : medicines = medicines ?? [],
        activityLogs = activityLogs ?? [];

  final String id;
  final String userId;
  final String password;
  final String name;
  final String age;
  final String photoPath;
  final String diseaseList;

  final List<MedicineEntry> medicines;
  final List<PatientActivityLog> activityLogs;

  int get totalMedicines => medicines.length;

  int get takenToday {
    return medicines.where((medicine) => medicine.isTakenToday).length;
  }

  int get missedToday {
    return medicines.where((medicine) => medicine.isMissedToday).length;
  }

  int get totalLogs => takenToday + missedToday;
}

class MedicineEntry {
  MedicineEntry({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.instruction,
    required this.times,
    required this.startDate,
    required this.endDate,
    Set<String>? takenPeriodKeys,
    Set<String>? missedPeriodKeys,
    Set<String>? takenDoseKeys,
    Set<String>? missedDoseKeys,
    this.isTakenToday = false,
    this.isMissedToday = false,
  })  : takenPeriodKeys = takenPeriodKeys ?? <String>{},
        missedPeriodKeys = missedPeriodKeys ?? <String>{},
        takenDoseKeys = takenDoseKeys ?? <String>{},
        missedDoseKeys = missedDoseKeys ?? <String>{};

  final String id;
  final String name;
  final String imagePath;
  final String instruction;
  final List<String> times;

  final DateTime startDate;
  final DateTime endDate;

  final Set<String> takenPeriodKeys;
  final Set<String> missedPeriodKeys;

  final Set<String> takenDoseKeys;
  final Set<String> missedDoseKeys;

  bool isTakenToday;
  bool isMissedToday;

  int get totalDays {
    return dateOnly(endDate).difference(dateOnly(startDate)).inDays + 1;
  }

  int get completedDays {
    final today = dateOnly(DateTime.now());
    final start = dateOnly(startDate);
    final end = dateOnly(endDate);

    if (today.isBefore(start)) return 0;
    if (today.isAfter(end)) return totalDays;

    return today.difference(start).inDays + 1;
  }

  int get remainingDays {
    final today = dateOnly(DateTime.now());
    final end = dateOnly(endDate);

    if (today.isAfter(end)) return 0;

    return end.difference(today).inDays + 1;
  }

  bool get isComplete {
    final today = dateOnly(DateTime.now());
    final end = dateOnly(endDate);

    return today.isAfter(end);
  }

  bool get isActiveToday {
    final today = dateOnly(DateTime.now());
    final start = dateOnly(startDate);
    final end = dateOnly(endDate);

    return !today.isBefore(start) && !today.isAfter(end);
  }

  String get statusText {
    if (isComplete) return 'Complete';
    if (!isActiveToday) return 'Upcoming';
    return 'Ongoing';
  }
}

class PatientActivityLog {
  PatientActivityLog({
    required this.id,
    required this.medicineName,
    required this.periodName,
    required this.status,
    required this.time,
    required this.date,
  });

  final String id;
  final String medicineName;
  final String periodName;
  final String status;
  final DateTime time;
  final DateTime date;
}