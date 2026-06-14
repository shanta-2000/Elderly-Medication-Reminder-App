import 'package:cloud_firestore/cloud_firestore.dart';

DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime parseFirebaseDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  return DateTime.now();
}

List<String> parseStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }

  return <String>[];
}

Set<String> parseStringSet(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toSet();
  }

  if (value is Set) {
    return value.map((item) => item.toString()).toSet();
  }

  return <String>{};
}

class Patient {
  Patient({
    required this.id,
    this.caregiverId = '',
    required this.userId,
    required this.password,
    required this.name,
    required this.age,
    required this.photoPath,
    this.photoUrl = '',
    required this.diseaseList,
    this.fcmToken = '',
    List<MedicineEntry>? medicines,
    List<PatientActivityLog>? activityLogs,
  })  : medicines = medicines ?? [],
        activityLogs = activityLogs ?? [];

  final String id;
  final String caregiverId;
  final String userId;
  final String password;
  final String name;
  final String age;
  final String photoPath;
  final String photoUrl;
  final String diseaseList;
  final String fcmToken;

  final List<MedicineEntry> medicines;
  final List<PatientActivityLog> activityLogs;

  int get totalMedicines => medicines.length;

  int get takenToday {
    return medicines.where((medicine) => medicine.isTakenToday).length;
  }

  int get missedToday {
    return medicines.where((medicine) => medicine.isMissedToday).length;
  }

  int get totalLogs => activityLogs.length;

  Patient copyWith({
    String? id,
    String? caregiverId,
    String? userId,
    String? password,
    String? name,
    String? age,
    String? photoPath,
    String? photoUrl,
    String? diseaseList,
    String? fcmToken,
    List<MedicineEntry>? medicines,
    List<PatientActivityLog>? activityLogs,
  }) {
    return Patient(
      id: id ?? this.id,
      caregiverId: caregiverId ?? this.caregiverId,
      userId: userId ?? this.userId,
      password: password ?? this.password,
      name: name ?? this.name,
      age: age ?? this.age,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      diseaseList: diseaseList ?? this.diseaseList,
      fcmToken: fcmToken ?? this.fcmToken,
      medicines: medicines ?? this.medicines,
      activityLogs: activityLogs ?? this.activityLogs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'caregiverId': caregiverId,
      'userId': userId,
      'password': password,
      'name': name,
      'age': age,
      'photoPath': photoPath,
      'photoUrl': photoUrl,
      'diseaseList': diseaseList,
      'fcmToken': fcmToken,
    };
  }

  factory Patient.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return Patient(
      id: id,
      caregiverId: map['caregiverId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      age: map['age']?.toString() ?? '',
      photoPath: map['photoPath']?.toString() ?? '',
      photoUrl: map['photoUrl']?.toString() ?? '',
      diseaseList: map['diseaseList']?.toString() ?? '',
      fcmToken: map['fcmToken']?.toString() ?? '',
    );
  }
}

class MedicineEntry {
  MedicineEntry({
    required this.id,
    this.caregiverId = '',
    this.patientId = '',
    required this.name,
    required this.imagePath,
    this.imageUrl = '',
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
  final String caregiverId;
  final String patientId;
  final String name;
  final String imagePath;
  final String imageUrl;
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

  MedicineEntry copyWith({
    String? id,
    String? caregiverId,
    String? patientId,
    String? name,
    String? imagePath,
    String? imageUrl,
    String? instruction,
    List<String>? times,
    DateTime? startDate,
    DateTime? endDate,
    Set<String>? takenPeriodKeys,
    Set<String>? missedPeriodKeys,
    Set<String>? takenDoseKeys,
    Set<String>? missedDoseKeys,
    bool? isTakenToday,
    bool? isMissedToday,
  }) {
    return MedicineEntry(
      id: id ?? this.id,
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      instruction: instruction ?? this.instruction,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      takenPeriodKeys: takenPeriodKeys ?? this.takenPeriodKeys,
      missedPeriodKeys: missedPeriodKeys ?? this.missedPeriodKeys,
      takenDoseKeys: takenDoseKeys ?? this.takenDoseKeys,
      missedDoseKeys: missedDoseKeys ?? this.missedDoseKeys,
      isTakenToday: isTakenToday ?? this.isTakenToday,
      isMissedToday: isMissedToday ?? this.isMissedToday,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'caregiverId': caregiverId,
      'patientId': patientId,
      'name': name,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'instruction': instruction,
      'times': times,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'takenPeriodKeys': takenPeriodKeys.toList(),
      'missedPeriodKeys': missedPeriodKeys.toList(),
      'takenDoseKeys': takenDoseKeys.toList(),
      'missedDoseKeys': missedDoseKeys.toList(),
      'isTakenToday': isTakenToday,
      'isMissedToday': isMissedToday,
    };
  }

  factory MedicineEntry.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return MedicineEntry(
      id: id,
      caregiverId: map['caregiverId']?.toString() ?? '',
      patientId: map['patientId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      imagePath: map['imagePath']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      instruction: map['instruction']?.toString() ?? '',
      times: parseStringList(map['times']),
      startDate: parseFirebaseDate(map['startDate']),
      endDate: parseFirebaseDate(map['endDate']),
      takenPeriodKeys: parseStringSet(map['takenPeriodKeys']),
      missedPeriodKeys: parseStringSet(map['missedPeriodKeys']),
      takenDoseKeys: parseStringSet(map['takenDoseKeys']),
      missedDoseKeys: parseStringSet(map['missedDoseKeys']),
      isTakenToday: map['isTakenToday'] == true,
      isMissedToday: map['isMissedToday'] == true,
    );
  }
}

class PatientActivityLog {
  PatientActivityLog({
    required this.id,
    this.caregiverId = '',
    this.patientId = '',
    this.medicineId = '',
    required this.medicineName,
    required this.periodName,
    required this.status,
    required this.time,
    required this.date,
  });

  final String id;
  final String caregiverId;
  final String patientId;
  final String medicineId;
  final String medicineName;
  final String periodName;
  final String status;
  final DateTime time;
  final DateTime date;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'caregiverId': caregiverId,
      'patientId': patientId,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'periodName': periodName,
      'status': status,
      'time': Timestamp.fromDate(time),
      'date': Timestamp.fromDate(date),
    };
  }

  factory PatientActivityLog.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return PatientActivityLog(
      id: id,
      caregiverId: map['caregiverId']?.toString() ?? '',
      patientId: map['patientId']?.toString() ?? '',
      medicineId: map['medicineId']?.toString() ?? '',
      medicineName: map['medicineName']?.toString() ?? '',
      periodName: map['periodName']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      time: parseFirebaseDate(map['time']),
      date: parseFirebaseDate(map['date']),
    );
  }
}