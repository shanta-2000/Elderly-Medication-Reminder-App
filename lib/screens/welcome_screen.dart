import 'package:flutter/material.dart';
import 'caregiver_account_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void goToCreateAccount(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const  CaregiverAccountScreen(),
      ),
    );
  }

  void goToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F2F2F),
      body: SafeArea(
        child: Center(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4C7DFF),
                  Color(0xFFB144F5),
                  Color(0xFFFF2D8C),
                ],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 42),

                // Top white circular logo placeholder
                Container(
                  width: 115,
                  height: 115,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                const Text(
                  'ওষুধ মনে রাখি',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 39,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Medicine Reminder',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'বয়স্কদের জন্য বিশ্বস্ততার সাথী',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 35),

                // Three dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    DotIndicator(),
                    SizedBox(width: 8),
                    DotIndicator(),
                    SizedBox(width: 8),
                    DotIndicator(),
                  ],
                ),

                const Spacer(),

                // Bottom white section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'স্বাগতম',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'শুরু করতে একটি অপশন বেছে নিন',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton.icon(
                          onPressed: () => goToCreateAccount(context),
                          icon: const Icon(Icons.person_add_alt_1, size: 25),
                          label: const Text(
                            'নতুন একাউন্ট তৈরি করুন',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                          ).copyWith(
                            backgroundColor:
                            WidgetStateProperty.all(Colors.transparent),
                          ),
                        ).withGradientBackground(),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: OutlinedButton.icon(
                          onPressed: () => goToLogin(context),
                          icon: const Icon(Icons.login, size: 25),
                          label: const Text(
                            'লগ ইন করুন',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB144F5),
                            side: const BorderSide(
                              color: Color(0xFFB144F5),
                              width: 1.3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'পরিচর্যাকারী ও রোগী উভয়ের জন্য',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DotIndicator extends StatelessWidget {
  const DotIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

// Gradient button helper
extension GradientButtonExtension on ElevatedButton {
  Widget withGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFB144F5),
            Color(0xFFFF2D8C),
          ],
        ),
      ),
      child: this,
    );
  }
}

// Temporary page. Later we will replace this with your real caregiver details page.
class CaregiverDetailsPlaceholderScreen extends StatelessWidget {
  const CaregiverDetailsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Details'),
      ),
      body: const Center(
        child: Text(
          'Caregiver details page will be added here.',
          style: TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// Temporary page. Later we will replace this with your real login page.
class LoginPlaceholderScreen extends StatelessWidget {
  const LoginPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: const Center(
        child: Text(
          'Login page will be added here.',
          style: TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}