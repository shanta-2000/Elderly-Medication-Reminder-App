import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'data/app_data.dart';
import 'firebase_options.dart';
import 'screens/caregiver_dashboard_screen.dart';
import 'screens/patient_dashboard_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/firebase_database_service.dart';
import 'services/session_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  try {
    final String? fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM TOKEN: $fcmToken');
  } catch (error) {
    debugPrint('FCM TOKEN ERROR: $error');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicine Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB144F5),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<Widget> startScreenFuture;

  @override
  void initState() {
    super.initState();
    startScreenFuture = getStartScreen();
  }

  Future<Widget> getStartScreen() async {
    final savedLogin = await SessionService.getSavedLogin();

    if (savedLogin == null) {
      return const WelcomeScreen();
    }

    try {
      if (savedLogin.role == SessionService.roleCaregiver) {
        final caregiver = await FirebaseDatabaseService.instance.loginCaregiver(
          userId: savedLogin.userId,
          password: savedLogin.password,
        );

        if (caregiver == null) {
          await SessionService.clearLogin();
          AppData.clearSession();
          return const WelcomeScreen();
        }

        AppData.saveCaregiver(caregiver);

        return CaregiverDashboardScreen(
          caregiverName: caregiver.fullName,
        );
      }

      if (savedLogin.role == SessionService.rolePatient) {
        final patient = await FirebaseDatabaseService.instance.loginPatient(
          userId: savedLogin.userId,
          password: savedLogin.password,
        );

        if (patient == null) {
          await SessionService.clearLogin();
          AppData.clearSession();
          return const WelcomeScreen();
        }

        AppData.savePatient(patient);

        return PatientDashboardScreen(patient: patient);
      }

      await SessionService.clearLogin();
      AppData.clearSession();
      return const WelcomeScreen();
    } catch (error) {
      debugPrint('AUTO LOGIN ERROR: $error');

      await SessionService.clearLogin();
      AppData.clearSession();

      return const WelcomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: startScreenFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!;
        }

        return const SplashLoadingScreen();
      },
    );
  }
}

class SplashLoadingScreen extends StatelessWidget {
  const SplashLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFB144F5),
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }
}