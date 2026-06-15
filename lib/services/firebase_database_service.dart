import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/caregiver_model.dart';
import '../models/patient_model.dart';

class FirebaseDatabaseService {
  FirebaseDatabaseService._();

  static final FirebaseDatabaseService instance = FirebaseDatabaseService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _caregivers {
    return _firestore.collection('caregivers');
  }

  CollectionReference<Map<String, dynamic>> get _patients {
    return _firestore.collection('patients');
  }

  CollectionReference<Map<String, dynamic>> get _medicines {
    return _firestore.collection('medicines');
  }

  CollectionReference<Map<String, dynamic>> get _activityLogs {
    return _firestore.collection('activity_logs');
  }

  Future<String> getFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      return token ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<Caregiver> saveCaregiver(Caregiver caregiver) async {
    final token = await getFcmToken();

    final docRef = caregiver.id.isEmpty
        ? _caregivers.doc()
        : _caregivers.doc(caregiver.id);

    final caregiverWithId = caregiver.copyWith(
      id: docRef.id,
      fcmToken: token,
    );

    await docRef.set({
      ...caregiverWithId.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return caregiverWithId;
  }

  Future<Caregiver?> loginCaregiver({
    required String userId,
    required String password,
  }) async {
    final snapshot = await _caregivers
        .where('userId', isEqualTo: userId)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;
    final token = await getFcmToken();

    await doc.reference.update({
      'fcmToken': token,
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    return Caregiver.fromMap(
      id: doc.id,
      map: doc.data(),
    ).copyWith(
      fcmToken: token,
    );
  }

  Future<Patient> savePatient(Patient patient) async {
    final docRef =
    patient.id.isEmpty ? _patients.doc() : _patients.doc(patient.id);

    final patientWithId = patient.copyWith(
      id: docRef.id,
    );

    final data = {
      ...patientWithId.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (patient.id.isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(
      data,
      SetOptions(merge: true),
    );

    return patientWithId;
  }

  Future<void> deletePatientWithRelatedData(String patientId) async {
    if (patientId.isEmpty) return;

    final batch = _firestore.batch();

    final medicinesSnapshot = await _medicines
        .where('patientId', isEqualTo: patientId)
        .get();

    for (final doc in medicinesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    final logsSnapshot = await _activityLogs
        .where('patientId', isEqualTo: patientId)
        .get();

    for (final doc in logsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_patients.doc(patientId));

    await batch.commit();
  }

  Future<List<Patient>> getPatientsByCaregiver(String caregiverId) async {
    final snapshot = await _patients
        .where('caregiverId', isEqualTo: caregiverId)
        .get();

    final patients = snapshot.docs.map((doc) {
      return Patient.fromMap(
        id: doc.id,
        map: doc.data(),
      );
    }).toList();

    patients.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return patients;
  }

  Stream<List<Patient>> watchPatientsByCaregiver(String caregiverId) {
    return _patients
        .where('caregiverId', isEqualTo: caregiverId)
        .snapshots()
        .map((snapshot) {
      final patients = snapshot.docs.map((doc) {
        return Patient.fromMap(
          id: doc.id,
          map: doc.data(),
        );
      }).toList();

      patients.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      return patients;
    });
  }

  Future<Patient?> loginPatient({
    required String userId,
    required String password,
  }) async {
    final snapshot = await _patients
        .where('userId', isEqualTo: userId)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;
    final token = await getFcmToken();

    await doc.reference.update({
      'fcmToken': token,
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    return Patient.fromMap(
      id: doc.id,
      map: doc.data(),
    ).copyWith(
      fcmToken: token,
    );
  }

  Future<MedicineEntry> saveMedicine(MedicineEntry medicine) async {
    final docRef =
    medicine.id.isEmpty ? _medicines.doc() : _medicines.doc(medicine.id);

    final medicineWithId = medicine.copyWith(
      id: docRef.id,
    );

    final data = {
      ...medicineWithId.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (medicine.id.isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(
      data,
      SetOptions(merge: true),
    );

    return medicineWithId;
  }

  Stream<List<MedicineEntry>> watchMedicinesByPatient(String patientId) {
    return _medicines
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      final medicines = snapshot.docs.map((doc) {
        return MedicineEntry.fromMap(
          id: doc.id,
          map: doc.data(),
        );
      }).toList();

      medicines.sort((a, b) => b.startDate.compareTo(a.startDate));

      return medicines;
    });
  }

  Future<List<MedicineEntry>> getMedicinesByPatient(String patientId) async {
    final snapshot = await _medicines
        .where('patientId', isEqualTo: patientId)
        .get();

    final medicines = snapshot.docs.map((doc) {
      return MedicineEntry.fromMap(
        id: doc.id,
        map: doc.data(),
      );
    }).toList();

    medicines.sort((a, b) => b.startDate.compareTo(a.startDate));

    return medicines;
  }

  Future<void> updateMedicineDoseStatus(MedicineEntry medicine) async {
    if (medicine.id.isEmpty) return;

    await _medicines.doc(medicine.id).update({
      'takenPeriodKeys': medicine.takenPeriodKeys.toList(),
      'missedPeriodKeys': medicine.missedPeriodKeys.toList(),
      'takenDoseKeys': medicine.takenDoseKeys.toList(),
      'missedDoseKeys': medicine.missedDoseKeys.toList(),
      'isTakenToday': medicine.isTakenToday,
      'isMissedToday': medicine.isMissedToday,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMedicine(String medicineId) async {
    if (medicineId.isEmpty) return;

    await _medicines.doc(medicineId).delete();
  }

  Future<void> saveActivityLog(PatientActivityLog log) async {
    final docRef =
    log.id.isEmpty ? _activityLogs.doc() : _activityLogs.doc(log.id);

    await docRef.set({
      ...log.toMap(),
      'id': docRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<PatientActivityLog>> watchActivityLogsByPatient(
      String patientId,
      ) {
    return _activityLogs
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      final logs = snapshot.docs.map((doc) {
        return PatientActivityLog.fromMap(
          id: doc.id,
          map: doc.data(),
        );
      }).toList();

      logs.sort((a, b) => b.time.compareTo(a.time));

      return logs;
    });
  }

  Future<List<PatientActivityLog>> getActivityLogsByPatient(
      String patientId,
      ) async {
    final snapshot = await _activityLogs
        .where('patientId', isEqualTo: patientId)
        .get();

    final logs = snapshot.docs.map((doc) {
      return PatientActivityLog.fromMap(
        id: doc.id,
        map: doc.data(),
      );
    }).toList();

    logs.sort((a, b) => b.time.compareTo(a.time));

    return logs;
  }
}