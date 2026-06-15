import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../models/patient_model.dart';
import '../services/firebase_database_service.dart';
import '../services/session_service.dart';
import 'add_patient_screen.dart' as add_patient;
import 'patient_list_screen.dart';
import 'welcome_screen.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({
    super.key,
    required this.caregiverName,
    this.showAccountCreatedDialog = false,
  });

  final String caregiverName;
  final bool showAccountCreatedDialog;

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  List<Patient> latestPatients = [];

  @override
  void initState() {
    super.initState();

    if (widget.showAccountCreatedDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showAccountCreatedDialog();
      });
    }
  }

  void showAccountCreatedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'একাউন্ট তৈরি হয়েছে',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'আপনার পরিচর্যাকারীর একাউন্ট সফলভাবে তৈরি হয়েছে।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
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
            style: TextStyle(fontSize: 16),
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

  Future<void> goToAddPatientPage() async {
    if (AppData.caregiver == null || AppData.caregiver!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('পরিচর্যাকারীর তথ্য পাওয়া যায়নি। আবার লগইন করুন।'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const add_patient.AddPatientScreen(),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  void goToPatientListPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientListScreen(
          patients: latestPatients,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caregiver = AppData.caregiver;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFB144F5),
                    Color(0xFFFF2D8C),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.medication_liquid,
                              color: Color(0xFFB144F5),
                              size: 24,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'পরিচর্যাকারী ড্যাশবোর্ড',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          caregiver?.fullName ?? widget.caregiverName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: showSignOutDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Color(0xFFB144F5),
                        size: 23,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: caregiver == null || caregiver.id.isEmpty
                  ? const Center(
                child: Text(
                  'পরিচর্যাকারীর তথ্য পাওয়া যায়নি। আবার লগইন করুন।',
                  textAlign: TextAlign.center,
                ),
              )
                  : StreamBuilder<List<Patient>>(
                stream: FirebaseDatabaseService.instance
                    .watchPatientsByCaregiver(caregiver.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'রোগীর তথ্য লোড করা যায়নি:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  latestPatients = snapshot.data ?? [];
                  AppData.patients
                    ..clear()
                    ..addAll(latestPatients);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    children: [
                      const Text(
                        'কি করতে চান?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DashboardActionCard(
                        icon: Icons.person_add_alt_1,
                        iconGradientColors: const [
                          Color(0xFFB144F5),
                          Color(0xFFFF2D8C),
                        ],
                        title: 'নতুন রোগী যোগ করুন',
                        subtitle: 'রোগীর তথ্য ও একাউন্ট তৈরি করুন',
                        onTap: goToAddPatientPage,
                      ),
                      const SizedBox(height: 14),
                      DashboardActionCard(
                        icon: Icons.groups_2_outlined,
                        iconGradientColors: const [
                          Color(0xFF00A6FF),
                          Color(0xFF00B2D8),
                        ],
                        title: 'রোগীদের তথ্য দেখুন',
                        subtitle:
                        'সব রোগীর ওষুধ ও কার্যকলাপ দেখুন (${latestPatients.length})',
                        onTap: goToPatientListPage,
                      ),
                      const SizedBox(height: 16),
                      PatientCountCard(
                        count: latestPatients.length,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFFC94D),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Color(0xFFFFB300),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'টিপস:\nপ্রথমে রোগী যোগ করুন, তারপর তাদের ওষুধের তালিকা তৈরি করুন।',
                                style: TextStyle(
                                  color: Color(0xFF8A5A00),
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class PatientCountCard extends StatelessWidget {
  const PatientCountCard({
    super.key,
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD8E7FF),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.people_alt_outlined,
            color: Color(0xFF2563EB),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Firestore থেকে মোট $count জন রোগী লোড হয়েছে',
              style: const TextStyle(
                color: Color(0xFF344054),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardActionCard extends StatelessWidget {
  const DashboardActionCard({
    super.key,
    required this.icon,
    required this.iconGradientColors,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final List<Color> iconGradientColors;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.12),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: iconGradientColors,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475467),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}