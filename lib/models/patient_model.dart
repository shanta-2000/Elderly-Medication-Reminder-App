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
  }) : medicines = medicines ?? [],
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
    Set<String>? takenPeriodKeys,
    Set<String>? missedPeriodKeys,
    this.isTakenToday = false,
    this.isMissedToday = false,
  })  : takenPeriodKeys = takenPeriodKeys ?? <String>{},
        missedPeriodKeys = missedPeriodKeys ?? <String>{};

  final String id;
  final String name;
  final String imagePath;
  final String instruction;
  final List<String> times;

  final Set<String> takenPeriodKeys;
  final Set<String> missedPeriodKeys;

  bool isTakenToday;
  bool isMissedToday;
}

class PatientActivityLog {
  PatientActivityLog({
    required this.id,
    required this.medicineName,
    required this.periodName,
    required this.status,
    required this.time,
  });

  final String id;
  final String medicineName;
  final String periodName;
  final String status;
  final DateTime time;
}