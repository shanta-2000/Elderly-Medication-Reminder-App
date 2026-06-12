import 'package:flutter/material.dart';

import '../models/patient_model.dart';
import 'add_patient_screen.dart';
import 'patient_list_screen.dart';
import '../data/app_data.dart';

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
      builder: (context) {
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

  Future<void> goToAddPatientPage() async {
    final Patient? newPatient = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddPatientScreen(),
      ),
    );

    if (newPatient != null) {
      setState(() {
        AppData.patients.add(newPatient);
      });
    }
  }

  void goToPatientListPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientListScreen(
          patients: AppData.patients,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          widget.caregiverName,
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
                        Icons.person,
                        color: Color(0xFFB144F5),
                        size: 25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
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
                    subtitle: 'সব রোগীর ওষুধ ও কার্যকলাপ দেখুন',
                    onTap: goToPatientListPage,
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
              ),
            ),
          ],
        ),
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