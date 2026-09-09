import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // ============================================================
  // CURRENT PATIENT
  // ============================================================

  User get currentUser {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No patient is logged in.');
    }

    return user;
  }

  String get uid => currentUser.uid;

  String get email => currentUser.email ?? '';

  // ============================================================
  // FIREBASE STRUCTURE
  // ============================================================

  DatabaseReference get userRef =>
      _database.ref('users/$uid');

  DatabaseReference get deviceRef =>
      userRef.child('device');

  DatabaseReference get latestRef =>
      userRef.child('latest');

  DatabaseReference get historyRef =>
      userRef.child('history');

  DatabaseReference get roomRef =>
      userRef.child('room');

  DatabaseReference get ecgRef =>
      userRef.child('ecg');

  DatabaseReference get profileRef =>
      userRef.child('profile');

  DatabaseReference get dailyRef =>
      userRef.child('daily');

  // ============================================================
  // ESP32 ACCOUNT CHECK
  // ============================================================

  Future<bool> hasRegisteredMedicareDevice() async {
    final snapshot = await deviceRef.get();

    if (!snapshot.exists) {
      return false;
    }

    if (snapshot.value is! Map) {
      return false;
    }

    final data =
        Map<dynamic, dynamic>.from(
      snapshot.value as Map,
    );

    final deviceId =
        data['deviceId']
            ?.toString()
            .trim();

    return deviceId != null &&
        deviceId.isNotEmpty;
  }

  Future<Map<dynamic, dynamic>?> getDeviceInfo() async {
    final snapshot =
        await deviceRef.get();

    if (!snapshot.exists ||
        snapshot.value is! Map) {
      return null;
    }

    return Map<dynamic, dynamic>.from(
      snapshot.value as Map,
    );
  }

  // ============================================================
  // REFERENCES
  // ============================================================

  Future<DatabaseReference> getLatestRef() async {
    return latestRef;
  }

  Future<DatabaseReference> getRoomRef() async {
    return roomRef;
  }

  Future<DatabaseReference> getHistoryRef() async {
    return historyRef;
  }

  Future<DatabaseReference> getEcgRef() async {
    return ecgRef;
  }

  // ============================================================
  // LATEST VITALS
  // ============================================================

  Future<Map<dynamic, dynamic>?> getLatestVitals() async {
    final snapshot =
        await latestRef.get();

    if (!snapshot.exists ||
        snapshot.value is! Map) {
      return null;
    }

    return Map<dynamic, dynamic>.from(
      snapshot.value as Map,
    );
  }

  // ============================================================
  // RECENT HISTORY
  // ============================================================

  Future<List<Map<String, dynamic>>> getRecentHistory({
    int limit = 20,
  }) async {
    final snapshot = await historyRef
        .orderByChild('timestamp')
        .limitToLast(limit)
        .get();

    if (!snapshot.exists ||
        snapshot.value is! Map) {
      return [];
    }

    final raw =
        Map<dynamic, dynamic>.from(
      snapshot.value as Map,
    );

    final records =
        <Map<String, dynamic>>[];

    for (final entry in raw.entries) {
      final value = entry.value;

      if (value is! Map) {
        continue;
      }

      final item =
          Map<String, dynamic>.from(
        value.map(
          (key, value) =>
              MapEntry(
            key.toString(),
            value,
          ),
        ),
      );

      item['firebaseKey'] =
          entry.key.toString();

      records.add(item);
    }

    records.sort(
      (a, b) {
        final aTimestamp =
            _toInt(
          a['timestamp'],
        );

        final bTimestamp =
            _toInt(
          b['timestamp'],
        );

        return bTimestamp.compareTo(
          aTimestamp,
        );
      },
    );

    return records;
  }

  // ============================================================
  // DAILY CHECK-IN HISTORY
  // ============================================================

  Future<List<Map<String, dynamic>>>
      getRecentDailyCheckIns({
    int limit = 14,
  }) async {
    final snapshot = await dailyRef
        .orderByChild('timestamp')
        .limitToLast(limit)
        .get();

    if (!snapshot.exists ||
        snapshot.value is! Map) {
      return [];
    }

    final raw =
        Map<dynamic, dynamic>.from(
      snapshot.value as Map,
    );

    final records =
        <Map<String, dynamic>>[];

    for (final entry in raw.entries) {
      final value = entry.value;

      if (value is! Map) {
        continue;
      }

      final item =
          Map<String, dynamic>.from(
        value.map(
          (key, value) =>
              MapEntry(
            key.toString(),
            value,
          ),
        ),
      );

      item['dateKey'] =
          entry.key.toString();

      records.add(item);
    }

    records.sort(
      (a, b) {
        final aTimestamp =
            _toInt(
          a['timestamp'],
        );

        final bTimestamp =
            _toInt(
          b['timestamp'],
        );

        return bTimestamp.compareTo(
          aTimestamp,
        );
      },
    );

    return records;
  }

  // ============================================================
  // PROFILE
  // ============================================================

  Future<void> saveProfile({
    required String name,
    required int age,
    required String gender,
  }) async {
    await profileRef.update({
      'name': name,
      'email': email,
      'age': age,
      'gender': gender,
      'updatedAt':
          ServerValue.timestamp,
    });

    await currentUser.updateDisplayName(
      name,
    );
  }

  Future<Map<dynamic, dynamic>?> getProfile() async {
    final snapshot =
        await profileRef.get();

    if (!snapshot.exists ||
        snapshot.value is! Map) {
      return null;
    }

    return Map<dynamic, dynamic>.from(
      snapshot.value as Map,
    );
  }

  // ============================================================
  // DAILY CHECK-IN
  // ============================================================

  String _todayKey() {
    final now =
        DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<bool> hasCompletedTodayCheckIn() async {
    final snapshot =
        await dailyRef
            .child(
              _todayKey(),
            )
            .get();

    return snapshot.exists;
  }

  Future<bool>
      hasCompletedDailyCheckInToday() async {
    return hasCompletedTodayCheckIn();
  }

  Future<void> saveDailyCheckIn({
    required String mood,
    required double sleepHours,
    String symptoms = '',
    String notes = '',
    String? sleepQuality,
    int? stressLevel,
    int? painLevel,
    String? appetite,
    bool fatigue = false,
    bool dizziness = false,
    bool shortnessOfBreath = false,
    bool chestDiscomfort = false,
    bool headache = false,
    bool nausea = false,
  }) async {
    final data =
        <String, Object?>{
      'mood': mood,
      'sleepHours': sleepHours,
      'symptoms': symptoms,
      'notes': notes,
      'timestamp':
          ServerValue.timestamp,
    };

    if (sleepQuality != null) {
      data['sleepQuality'] =
          sleepQuality;
    }

    if (stressLevel != null) {
      data['stressLevel'] =
          stressLevel;
    }

    if (painLevel != null) {
      data['painLevel'] =
          painLevel;
    }

    if (appetite != null) {
      data['appetite'] =
          appetite;
    }

    data['fatigue'] =
        fatigue;

    data['dizziness'] =
        dizziness;

    data['shortnessOfBreath'] =
        shortnessOfBreath;

    data['chestDiscomfort'] =
        chestDiscomfort;

    data['headache'] =
        headache;

    data['nausea'] =
        nausea;

    await dailyRef
        .child(
          _todayKey(),
        )
        .set(data);
  }

  // ============================================================
  // HELPER
  // ============================================================

  int _toInt(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }
}