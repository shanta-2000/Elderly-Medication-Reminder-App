import '../models/caregiver_model.dart';
import '../models/patient_model.dart';

class AppData {
  static Caregiver? caregiver;
  static Patient? currentPatient;

  static final List<Patient> patients = [];

  static void saveCaregiver(Caregiver newCaregiver) {
    caregiver = newCaregiver;
  }

  static void savePatient(Patient patient) {
    currentPatient = patient;
  }

  static void clearSession() {
    caregiver = null;
    currentPatient = null;
    patients.clear();
  }

  static bool caregiverLoginMatched({
    required String userId,
    required String password,
  }) {
    if (caregiver == null) return false;

    return caregiver!.userId == userId && caregiver!.password == password;
  }

  static Patient? findPatientByLogin({
    required String userId,
    required String password,
  }) {
    for (final patient in patients) {
      if (patient.userId == userId && patient.password == password) {
        return patient;
      }
    }

    return null;
  }
}