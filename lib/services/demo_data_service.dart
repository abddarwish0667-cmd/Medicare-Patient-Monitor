import 'dart:math';

class DemoDataService {
  DemoDataService._();

  // ============================================================
  // DEMO PATIENT
  // ============================================================

  static const String patientName = 'Demo Patient';
  static const String patientEmail = 'demo@medicare.app';
  static const String deviceId = 'MEDICARE-DEMO-001';

  // ============================================================
  // CURRENT VITALS
  // ============================================================

  static Map<String, dynamic> get currentVitals {
    return {
      'heartRate': 78,
      'spo2': 98,
      'bodyTemperature': 36.8,
      'roomTemperature': 24.5,
      'humidity': 55,
      'batteryPercent': 82,
      'alert': false,
      'ecgLeadOff': false,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // ============================================================
  // SAMPLE HISTORY
  // ============================================================

  static List<Map<String, dynamic>> get history {
    final now = DateTime.now();

    return [
      _historyRecord(
        now.subtract(const Duration(days: 6)),
        72,
        98,
        36.6,
      ),
      _historyRecord(
        now.subtract(const Duration(days: 5)),
        74,
        98,
        36.7,
      ),
      _historyRecord(
        now.subtract(const Duration(days: 4)),
        76,
        97,
        36.7,
      ),
      _historyRecord(
        now.subtract(const Duration(days: 3)),
        77,
        98,
        36.8,
      ),
      _historyRecord(
        now.subtract(const Duration(days: 2)),
        79,
        97,
        36.8,
      ),
      _historyRecord(
        now.subtract(const Duration(days: 1)),
        77,
        98,
        36.7,
      ),
      _historyRecord(
        now,
        78,
        98,
        36.8,
      ),
    ];
  }

  static Map<String, dynamic> _historyRecord(
    DateTime date,
    int heartRate,
    int spo2,
    double temperature,
  ) {
    return {
      'heartRate': heartRate,
      'spo2': spo2,
      'bodyTemperature': temperature,
      'roomTemperature': 24.5,
      'humidity': 55,
      'batteryPercent': 82,
      'alert': false,
      'ecgLeadOff': false,
      'timestamp': date.millisecondsSinceEpoch,
    };
  }

  // ============================================================
  // DEMO DAILY CHECK-IN
  // ============================================================

  static Map<String, dynamic> get dailyCheckIn {
    return {
      'feeling': 'Good',
      'sleepHours': 7.5,
      'sleepQuality': 'Good',
      'pain': false,
      'dizziness': false,
      'shortnessOfBreath': false,
      'fatigue': 'Mild',
      'notes': 'Demo patient check-in.',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // ============================================================
  // DEMO ECG
  // ============================================================

  static List<double> generateEcg({
    int samples = 300,
  }) {
    final random = Random(42);

    return List.generate(samples, (index) {
      final position = index % 50;

      double value = 0;

      // Small baseline variation.
      value += sin(index / 8) * 0.03;

      // P wave.
      if (position >= 7 && position <= 11) {
        value +=
            sin((position - 7) / 4 * pi) * 0.12;
      }

      // Q wave.
      if (position == 18) {
        value -= 0.15;
      }

      // R wave.
      if (position == 19) {
        value += 1.0;
      }

      // S wave.
      if (position == 20) {
        value -= 0.25;
      }

      // T wave.
      if (position >= 28 && position <= 36) {
        value +=
            sin((position - 28) / 8 * pi) * 0.22;
      }

      // Very small simulated signal noise.
      value += (random.nextDouble() - 0.5) * 0.025;

      return value;
    });
  }

  // ============================================================
  // DEMO EARLY-DETECTION INFORMATION
  // ============================================================

  static Map<String, dynamic> get earlyDetection {
    return {
      'riskLevel': 'Low',
      'score': 18,
      'trend': 'Stable',
      'summary':
          'Demo measurements are generally stable with no major '
          'worsening trend detected in the sample data.',
      'recommendation':
          'Continue routine monitoring. This demonstration is '
          'for decision-support visualization only and is not '
          'a medical diagnosis.',
    };
  }

  // ============================================================
  // DEMO AI CONTEXT
  // ============================================================

  static String get aiContext {
    final vitals = currentVitals;

    return '''
MEDICARE DEMONSTRATION DATA

Patient: $patientName
Device: $deviceId

Heart Rate: ${vitals['heartRate']} bpm
SpO2: ${vitals['spo2']} %
Body Temperature: ${vitals['bodyTemperature']} °C
Room Temperature: ${vitals['roomTemperature']} °C
Humidity: ${vitals['humidity']} %
ECG electrodes connected: Yes

Daily Check-In:
Feeling: Good
Sleep: 7.5 hours
Sleep quality: Good
Pain: No
Dizziness: No
Shortness of breath: No
Fatigue: Mild

IMPORTANT:
These are simulated demonstration measurements.
They are not measurements from a real patient and must not be
treated as medical information.
''';
  }
}