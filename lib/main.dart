import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

import 'screens/ai_analysis_screen.dart';
import 'screens/daily_checkin_screen.dart';
import 'screens/early_detection_screen.dart';
import 'screens/ecg_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/history_screen.dart';
import 'screens/nearby_care_screen.dart';
import 'screens/profile_screen.dart';

import 'services/database_service.dart';
import 'services/app_mode.dart';
import 'services/demo_data_service.dart';

// =============================================================
// COLORS
// =============================================================

const Color medicareNavy = Color(0xFF082B5C);
const Color medicareBlue = Color(0xFF0968D8);
const Color medicareLightBlue = Color(0xFFEAF4FF);
const Color medicareBackground = Color(0xFFF5F8FC);
const Color medicareText = Color(0xFF12263F);
const Color medicareMuted = Color(0xFF718096);

// =============================================================
// MAIN
// =============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MedicareApp());
}

// =============================================================
// APP
// =============================================================

class MedicareApp extends StatelessWidget {
  const MedicareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medicare',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: medicareBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: medicareBlue),
        appBarTheme: const AppBarTheme(
          backgroundColor: medicareBackground,
          foregroundColor: medicareNavy,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.blueGrey.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: medicareBlue, width: 1.8),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// =============================================================
// HELPERS
// =============================================================

double? asDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

int? asInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

bool asBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value == 1 || value == '1') {
    return true;
  }

  return value.toString().toLowerCase() == 'true';
}

// =============================================================
// SPLASH
// =============================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), _checkLogin);
  }

  Future<void> _checkLogin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) {
      return;
    }

    if (user == null) {
      _goLogin();
      return;
    }

    try {
      final database = DatabaseService();

      final hasDevice = await database.hasRegisteredMedicareDevice();

      if (!mounted) {
        return;
      }

      if (hasDevice) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      } else {
        await FirebaseAuth.instance.signOut();

        if (!mounted) {
          return;
        }

        _goLogin();
      }
    } catch (_) {
      await FirebaseAuth.instance.signOut();

      if (!mounted) {
        return;
      }

      _goLogin();
    }
  }

  void _goLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/medicare_hook.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// =============================================================
// LOGIN ONLY
// =============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  void _message(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _login() async {
    final email = emailController.text.trim();

    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _message(
        'Enter the same email and password created on your Medicare ESP32.',
      );

      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final database = DatabaseService();

      final hasDevice = await database.hasRegisteredMedicareDevice();

      if (!mounted) {
        return;
      }

      if (!hasDevice) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) {
          return;
        }

        _message(
          'No Medicare ESP32 is registered for this account.\n\nCreate the account on the ESP32 first.',
        );

        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Unable to sign in.';

      if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        message =
            'Incorrect email or password.\n\nUse exactly the account created on the ESP32.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many login attempts. Try again later.';
      } else if (e.code == 'network-request-failed') {
        message = 'Check your internet connection.';
      }

      _message(message);
    } catch (e) {
      _message('Unable to open Medicare account.\n$e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _exploreDemo() {
    AppMode.enableDemo();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _message('Enter your Medicare account email first.');

      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      _message('Password reset email sent.');
    } on FirebaseAuthException catch (e) {
      _message(e.message ?? 'Unable to send password reset email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: medicareBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            children: [
              const SizedBox(height: 18),

              Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset('assets/images/medicare_icon.png'),
              ),

              const SizedBox(height: 20),

              const Text(
                'MEDICARE',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: medicareNavy,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Patient Monitoring System',
                style: TextStyle(fontSize: 15, color: medicareMuted),
              ),

              const SizedBox(height: 38),

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient Login',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: medicareText,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Use the email and password created on your Medicare ESP32.',
                      style: TextStyle(color: medicareMuted, height: 1.4),
                    ),

                    const SizedBox(height: 22),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Medicare email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: passwordController,
                      obscureText: hidePassword,
                      onSubmitted: (_) {
                        if (!loading) {
                          _login();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
                          },
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: medicareBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        icon: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login_rounded),
                        label: Text(
                          loading ? 'SIGNING IN...' : 'SIGN IN',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : _exploreDemo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF673AB7),
                    side: const BorderSide(
                      color: Color(0xFFB39DDB),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text(
                    'EXPLORE DEMO',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'No ESP32 or account required • Simulated data only',
                textAlign: TextAlign.center,
                style: TextStyle(color: medicareMuted, fontSize: 11),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: medicareLightBlue,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.developer_board_rounded, color: medicareBlue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'New patient? Create the account directly on the Medicare ESP32 first. The mobile app is login-only.',
                        style: TextStyle(color: medicareNavy, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Powered by Abd Elkoudous',
                style: TextStyle(color: medicareMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// HOME
// =============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService database = DatabaseService();

  String? profilePhotoPath;

  DatabaseReference? latestRef;
  DatabaseReference? roomRef;

  bool loadingDevice = true;
  String? deviceError;

  bool dailyCheckChecked = false;

  @override
  void initState() {
    super.initState();

    _loadProfilePhoto();

    if (AppMode.isDemo) {
      loadingDevice = false;
    } else {
      _loadReferences();
    }
  }

  Future<void> _loadReferences() async {
    try {
      final latest = await database.getLatestRef();

      final room = await database.getRoomRef();

      if (!mounted) {
        return;
      }

      setState(() {
        latestRef = latest;
        roomRef = room;
        loadingDevice = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAutomaticDailyCheckIn();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        loadingDevice = false;
        deviceError = e.toString();
      });
    }
  }

  Future<void> _checkAutomaticDailyCheckIn() async {
    if (AppMode.isDemo) {
      return;
    }

    if (dailyCheckChecked) {
      return;
    }

    dailyCheckChecked = true;

    try {
      final completed = await database.hasCompletedTodayCheckIn();

      if (!mounted || completed) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 600));

      if (!mounted) {
        return;
      }

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const DailyCheckInScreen(),
        ),
      );

      if (!mounted) {
        return;
      }

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Today\'s Medicare check-in is complete.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Daily check-in error: $e');
    }
  }

  Future<void> _loadProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();

    final path = prefs.getString('medicare_profile_photo');

    if (!mounted) {
      return;
    }

    setState(() {
      profilePhotoPath = path;
    });
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );

    await _loadProfilePhoto();
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _avatar() {
    final path = profilePhotoPath;

    if (path != null && File(path).existsSync()) {
      return CircleAvatar(radius: 20, backgroundImage: FileImage(File(path)));
    }

    return const CircleAvatar(
      radius: 20,
      backgroundColor: medicareLightBlue,
      child: Icon(Icons.person_rounded, color: medicareBlue),
    );
  }

  Future<void> _logout() async {
    if (AppMode.isDemo) {
      AppMode.enableRealDevice();
    } else {
      await FirebaseAuth.instance.signOut();
    }

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget _buildDemoHome() {
    final latest = Map<dynamic, dynamic>.from(DemoDataService.currentVitals);
    final heartRate = asInt(latest['heartRate']);
    final spo2 = asInt(latest['spo2']);
    final bodyTemperature = asDouble(latest['bodyTemperature']);
    final roomTemperature = asDouble(latest['roomTemperature']);
    final humidity = asDouble(latest['humidity']);
    final battery = asInt(latest['batteryPercent']) ?? 86;
    final alert = asBool(latest['alert']);
    final ecgLeadOff = asBool(latest['ecgLeadOff']);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Row(
          children: [
            Image.asset(
              'assets/images/medicare_icon.png',
              width: 42,
              height: 42,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MEDICARE',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Patient Monitoring System',
                    style: TextStyle(fontSize: 10, color: medicareMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'DEMO',
                style: TextStyle(
                  color: Color(0xFF673AB7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Exit Demo',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 35),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7F6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.science_outlined, color: Color(0xFF673AB7)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'DEMONSTRATION MODE • All health measurements shown here are simulated. No ESP32 or patient account is connected.',
                    style: TextStyle(
                      color: Color(0xFF512DA8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Welcome to,', style: TextStyle(color: medicareMuted)),
          const Text(
            'Medicare Demo',
            style: TextStyle(
              color: medicareNavy,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Simulated patient • No account required',
            style: TextStyle(color: medicareMuted, fontSize: 12),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: alert
                    ? const [Color(0xFF9E1C1C), Color(0xFFE04444)]
                    : const [medicareNavy, medicareBlue],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.monitor_heart_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Simulated Checkup',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _StatusChip(alert: alert),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: _Vital(
                        icon: Icons.favorite_rounded,
                        value: heartRate == null ? '--' : '$heartRate',
                        unit: 'bpm',
                        title: 'HEART RATE',
                      ),
                    ),
                    Expanded(
                      child: _Vital(
                        icon: Icons.water_drop_rounded,
                        value: spo2 == null ? '--' : '$spo2',
                        unit: '%',
                        title: 'SpO₂',
                      ),
                    ),
                    Expanded(
                      child: _Vital(
                        icon: Icons.thermostat_rounded,
                        value: bodyTemperature == null
                            ? '--'
                            : bodyTemperature.toStringAsFixed(1),
                        unit: '°C',
                        title: 'TEMP',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: _MiniCard(
                  icon: Icons.home_outlined,
                  title: 'Room',
                  value: roomTemperature == null
                      ? '-- °C'
                      : '${roomTemperature.toStringAsFixed(1)} °C',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniCard(
                  icon: Icons.water_drop_outlined,
                  title: 'Humidity',
                  value: humidity == null
                      ? '-- %'
                      : '${humidity.toStringAsFixed(0)} %',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniCard(
                  icon: Icons.battery_5_bar_rounded,
                  title: 'Battery',
                  value: '$battery %',
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _open(const EcgScreen()),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.monitor_heart_outlined,
                    color: ecgLeadOff ? Colors.orange : Colors.green,
                    size: 30,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Demo ECG Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          ecgLeadOff
                              ? 'Simulated electrodes disconnected'
                              : 'Simulated signal • Tap to view',
                          style: TextStyle(
                            color: ecgLeadOff ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 27),
          const Text(
            'Health Center',
            style: TextStyle(
              color: medicareNavy,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              _ActionCard(
                icon: Icons.history_rounded,
                title: 'History',
                subtitle: 'Simulated checkups',
                onTap: () => _open(const HistoryScreen()),
              ),
              _ActionCard(
                icon: Icons.monitor_heart_rounded,
                title: 'ECG Monitor',
                subtitle: 'Simulated waveform',
                special: true,
                onTap: () => _open(const EcgScreen()),
              ),
              _ActionCard(
                icon: Icons.psychology_alt_outlined,
                title: 'AI Analysis',
                subtitle: 'Demo assessment',
                special: true,
                onTap: () => _open(const AiAnalysisScreen()),
              ),
              _ActionCard(
                icon: Icons.insights_rounded,
                title: 'Early Detection',
                subtitle: 'Demo health trends',
                special: true,
                onTap: () => _open(const EarlyDetectionScreen()),
              ),
              _ActionCard(
                icon: Icons.local_hospital_outlined,
                title: 'Nearby Care',
                subtitle: 'Hospitals & clinics',
                onTap: () => _open(const NearbyCareScreen()),
              ),
              _ActionCard(
                icon: Icons.emergency_rounded,
                title: 'Emergency Call',
                subtitle: 'Red Cross & relief',
                emergency: true,
                onTap: () => _open(const EmergencyScreen()),
              ),
              _ActionCard(
                icon: Icons.bedtime_outlined,
                title: 'Daily Check-In',
                subtitle: 'Simulated wellness',
                onTap: () => _open(const DailyCheckInScreen()),
              ),
              _ActionCard(
                icon: Icons.exit_to_app_rounded,
                title: 'Exit Demo',
                subtitle: 'Return to patient login',
                onTap: _logout,
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFFB97800)),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Demo Mode is for showcasing Medicare only. All measurements are simulated and must not be interpreted as medical information or a diagnosis.',
                    style: TextStyle(
                      color: Color(0xFF795B24),
                      height: 1.4,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDemo = AppMode.isDemo;

    if (!isDemo && user == null) {
      return const LoginScreen();
    }

    if (isDemo) {
      return _buildDemoHome();
    }

    if (loadingDevice) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (deviceError != null || latestRef == null || roomRef == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('MEDICARE')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 65,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to load Medicare data',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  deviceError ?? 'Unknown error.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      loadingDevice = true;
                      deviceError = null;
                    });

                    _loadReferences();
                  },
                  child: const Text('RETRY'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final name = user?.displayName?.trim();

    final displayName = name != null && name.isNotEmpty ? name : 'Patient';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Row(
          children: [
            Image.asset(
              'assets/images/medicare_icon.png',
              width: 42,
              height: 42,
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MEDICARE',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Patient Monitoring System',
                  style: TextStyle(fontSize: 10, color: medicareMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          GestureDetector(onTap: _openProfile, child: _avatar()),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: latestRef!.onValue,
        builder: (context, latestSnapshot) {
          Map<dynamic, dynamic>? latest;

          final raw = latestSnapshot.data?.snapshot.value;

          if (raw is Map) {
            latest = Map<dynamic, dynamic>.from(raw);
          }

          final heartRate = asInt(latest?['heartRate']);

          final spo2 = asInt(latest?['spo2']);

          final bodyTemperature = asDouble(latest?['bodyTemperature']);

          final battery = asInt(latest?['batteryPercent']);

          final alert = asBool(latest?['alert']);

          final ecgLeadOff = latest == null
              ? true
              : asBool(latest['ecgLeadOff']);

          return StreamBuilder<DatabaseEvent>(
            stream: roomRef!.onValue,
            builder: (context, roomSnapshot) {
              double? roomTemperature;

              double? humidity;

              final roomRaw = roomSnapshot.data?.snapshot.value;

              if (roomRaw is Map) {
                final room = Map<dynamic, dynamic>.from(roomRaw);

                roomTemperature = asDouble(room['temperature']);

                humidity = asDouble(room['humidity']);
              }

              roomTemperature ??= asDouble(latest?['roomTemperature']);

              humidity ??= asDouble(latest?['humidity']);

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 35),
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(color: Colors.blueGrey.shade500),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    displayName,
                    style: const TextStyle(
                      color: medicareNavy,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: medicareMuted, fontSize: 12),
                  ),

                  const SizedBox(height: 22),

                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: alert
                            ? const [Color(0xFF9E1C1C), Color(0xFFE04444)]
                            : const [medicareNavy, medicareBlue],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.monitor_heart_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Latest Checkup',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _StatusChip(alert: alert),
                          ],
                        ),

                        const SizedBox(height: 25),

                        Row(
                          children: [
                            Expanded(
                              child: _Vital(
                                icon: Icons.favorite_rounded,
                                value: heartRate == null ? '--' : '$heartRate',
                                unit: 'bpm',
                                title: 'HEART RATE',
                              ),
                            ),
                            Expanded(
                              child: _Vital(
                                icon: Icons.water_drop_rounded,
                                value: spo2 == null ? '--' : '$spo2',
                                unit: '%',
                                title: 'SpO₂',
                              ),
                            ),
                            Expanded(
                              child: _Vital(
                                icon: Icons.thermostat_rounded,
                                value: bodyTemperature == null
                                    ? '--'
                                    : bodyTemperature.toStringAsFixed(1),
                                unit: '°C',
                                title: 'TEMP',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 17),

                  Row(
                    children: [
                      Expanded(
                        child: _MiniCard(
                          icon: Icons.home_outlined,
                          title: 'Room',
                          value: roomTemperature == null
                              ? '-- °C'
                              : '${roomTemperature.toStringAsFixed(1)} °C',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniCard(
                          icon: Icons.water_drop_outlined,
                          title: 'Humidity',
                          value: humidity == null
                              ? '-- %'
                              : '${humidity.toStringAsFixed(0)} %',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniCard(
                          icon: Icons.battery_5_bar_rounded,
                          title: 'Battery',
                          value: battery == null ? '-- %' : '$battery %',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 17),

                  InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _open(const EcgScreen()),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.monitor_heart_outlined,
                            color: ecgLeadOff ? Colors.orange : Colors.green,
                            size: 30,
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ECG Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  ecgLeadOff
                                      ? 'Electrodes disconnected'
                                      : 'Signal captured • Tap to view',
                                  style: TextStyle(
                                    color: ecgLeadOff
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 27),

                  const Text(
                    'Health Center',
                    style: TextStyle(
                      color: medicareNavy,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 14),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.05,
                    children: [
                      _ActionCard(
                        icon: Icons.history_rounded,
                        title: 'History',
                        subtitle: 'Previous checkups',
                        onTap: () => _open(const HistoryScreen()),
                      ),

                      _ActionCard(
                        icon: Icons.monitor_heart_rounded,
                        title: 'ECG Monitor',
                        subtitle: 'View ECG waveform',
                        special: true,
                        onTap: () => _open(const EcgScreen()),
                      ),

                      _ActionCard(
                        icon: Icons.psychology_alt_outlined,
                        title: 'AI Analysis',
                        subtitle: 'Analyze your vitals',
                        special: true,
                        onTap: () => _open(const AiAnalysisScreen()),
                      ),

                      _ActionCard(
                        icon: Icons.insights_rounded,
                        title: 'Early Detection',
                        subtitle: 'Analyze health trends',
                        special: true,
                        onTap: () => _open(const EarlyDetectionScreen()),
                      ),

                      _ActionCard(
                        icon: Icons.local_hospital_outlined,
                        title: 'Nearby Care',
                        subtitle: 'Hospitals & clinics',
                        onTap: () => _open(const NearbyCareScreen()),
                      ),

                      _ActionCard(
                        icon: Icons.emergency_rounded,
                        title: 'Emergency Call',
                        subtitle: 'Red Cross & relief',
                        emergency: true,
                        onTap: () => _open(const EmergencyScreen()),
                      ),

                      _ActionCard(
                        icon: Icons.bedtime_outlined,
                        title: 'Daily Check-In',
                        subtitle: 'Daily health questions',
                        onTap: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DailyCheckInScreen(),
                            ),
                          );

                          if (!context.mounted) {
                            return;
                          }

                          if (result == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Daily check-in updated.'),
                              ),
                            );
                          }
                        },
                      ),

                      _ActionCard(
                        icon: Icons.person_outline,
                        title: 'Profile',
                        subtitle: 'Account & picture',
                        onTap: _openProfile,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFB97800),
                        ),
                        SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'Medicare provides monitoring, trend analysis and decision support. It does not replace professional medical diagnosis.',
                            style: TextStyle(
                              color: Color(0xFF795B24),
                              height: 1.4,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// =============================================================
// STATUS
// =============================================================

class _StatusChip extends StatelessWidget {
  final bool alert;

  const _StatusChip({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        alert ? 'ALERT' : 'NORMAL',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// =============================================================
// VITAL
// =============================================================

class _Vital extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String title;

  const _Vital({
    required this.icon,
    required this.value,
    required this.unit,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 21),
        const SizedBox(height: 7),
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 9)),
        const SizedBox(height: 3),
        FittedBox(
          child: Text(
            '$value $unit',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// MINI CARD
// =============================================================

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MiniCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE7ECF2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: medicareBlue, size: 23),
          const SizedBox(height: 7),
          Text(
            title,
            style: const TextStyle(color: medicareMuted, fontSize: 10),
          ),
          const SizedBox(height: 3),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                color: medicareText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// ACTION CARD
// =============================================================

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool special;
  final bool emergency;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.special = false,
    this.emergency = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = emergency
        ? const Color(0xFFFFEFEF)
        : special
        ? const Color(0xFFEEF6FF)
        : Colors.white;

    final borderColor = emergency
        ? const Color(0xFFF4B7B7)
        : special
        ? const Color(0xFFB9D9FA)
        : const Color(0xFFE7ECF2);

    final iconBackground = emergency
        ? const Color(0xFFFFDADA)
        : medicareLightBlue;

    final iconColor = emergency ? const Color(0xFFD62F2F) : medicareBlue;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor),
              ),

              const Spacer(),

              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: emergency ? const Color(0xFF9E1C1C) : medicareText,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: medicareMuted,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
