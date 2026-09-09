import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import '../services/database_service.dart';

class AiAnalysisScreen extends StatefulWidget {
  const AiAnalysisScreen({super.key});

  @override
  State<AiAnalysisScreen> createState() =>
      _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen> {
  final DatabaseService database = DatabaseService();
  final AiService aiService = AiService();

  bool loading = false;
  bool loadingData = true;

  String? error;
  String? analysis;

  Map<dynamic, dynamic>? latestVitals;

  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> dailyCheckIns = [];

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  // ============================================================
  // LOAD REAL FIREBASE DATA
  // ============================================================

  Future<void> _loadPatientData() async {
    setState(() {
      loadingData = true;
      error = null;
      analysis = null;
    });

    try {
      final results = await Future.wait([
        database.getLatestVitals(),
        database.getRecentHistory(limit: 20),
        database.getRecentDailyCheckIns(limit: 14),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        latestVitals =
            results[0] as Map<dynamic, dynamic>?;

        history =
            results[1] as List<Map<String, dynamic>>;

        dailyCheckIns =
            results[2] as List<Map<String, dynamic>>;

        loadingData = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        loadingData = false;
        error = 'Unable to load patient data.\n$e';
      });
    }
  }

  // ============================================================
  // RUN AI
  // ============================================================

  Future<void> _runAnalysis() async {
    if (loading) {
      return;
    }

    if (latestVitals == null &&
        history.isEmpty &&
        dailyCheckIns.isEmpty) {
      setState(() {
        error =
            'There is not enough patient data to analyze yet.';
      });

      return;
    }

    setState(() {
      loading = true;
      error = null;
      analysis = null;
    });

    try {
      final result =
          await aiService.analyzeComprehensive(
        latestVitals: latestVitals,
        history: history,
        dailyCheckIns: dailyCheckIns,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        analysis = result;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        error = 'AI analysis failed.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int? _toInt(dynamic value) {
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

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value == 1 || value == '1') {
      return true;
    }

    return value.toString().toLowerCase() == 'true';
  }

  Color _riskColor() {
    final text = analysis?.toUpperCase() ?? '';

    if (text.contains('RISK LEVEL: HIGH')) {
      return Colors.red;
    }

    if (text.contains('RISK LEVEL: MODERATE')) {
      return Colors.orange;
    }

    if (text.contains('RISK LEVEL: LOW')) {
      return Colors.green;
    }

    return Colors.blueGrey;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF082B5C);
    const blue = Color(0xFF0968D8);
    const background = Color(0xFFF5F8FC);

    final latest = latestVitals;

    final heartRate =
        _toInt(latest?['heartRate']);

    final spo2 =
        _toInt(latest?['spo2']);

    final temperature =
        _toDouble(latest?['bodyTemperature']);

    final alert =
        _toBool(latest?['alert']);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'AI Analysis',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'LIVE DATA',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh data',
            onPressed:
                loadingData ? null : _loadPatientData,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: loadingData
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                35,
              ),
              children: [
                // =================================================
                // HEADER
                // =================================================

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        navy,
                        blue,
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(27),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.psychology_alt_rounded,
                        color: Colors.white,
                        size: 49,
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Medicare AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'ESP32 measurements + history + Daily Check-Ins',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // =================================================
                // DATA AVAILABLE
                // =================================================

                const Text(
                  'Patient Data',
                  style: TextStyle(
                    color: navy,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _CountCard(
                        icon:
                            Icons.monitor_heart_outlined,
                        title: 'Checkups',
                        value: '${history.length}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CountCard(
                        icon: Icons
                            .assignment_turned_in_outlined,
                        title: 'Check-Ins',
                        value:
                            '${dailyCheckIns.length}',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // =================================================
                // REAL VITALS
                // =================================================

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFE5EBF2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.monitor_heart_rounded,
                            color: blue,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Latest Measurements',
                              style: TextStyle(
                                color: navy,
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: alert
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                            child: Text(
                              alert
                                  ? 'ALERT'
                                  : 'NORMAL',
                              style: TextStyle(
                                color: alert
                                    ? Colors.red
                                    : Colors.green,
                                fontSize: 9,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _VitalSummary(
                              icon:
                                  Icons.favorite_rounded,
                              title: 'Heart Rate',
                              value: heartRate == null
                                  ? '--'
                                  : '$heartRate',
                              unit: 'bpm',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _VitalSummary(
                              icon: Icons
                                  .water_drop_rounded,
                              title: 'SpO₂',
                              value: spo2 == null
                                  ? '--'
                                  : '$spo2',
                              unit: '%',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _VitalSummary(
                              icon:
                                  Icons.thermostat_rounded,
                              title: 'Temp',
                              value: temperature == null
                                  ? '--'
                                  : temperature
                                      .toStringAsFixed(1),
                              unit: '°C',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // =================================================
                // DAILY CHECK-IN
                // =================================================

                if (dailyCheckIns.isNotEmpty)
                  _LatestCheckInCard(
                    data: dailyCheckIns.first,
                  ),

                if (dailyCheckIns.isNotEmpty)
                  const SizedBox(height: 18),

                // =================================================
                // AI BUTTON
                // =================================================

                SizedBox(
                  height: 59,
                  child: ElevatedButton.icon(
                    onPressed:
                        loading ? null : _runAnalysis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                    ),
                    icon: loading
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.auto_awesome_rounded,
                          ),
                    label: Text(
                      loading
                          ? 'ANALYZING...'
                          : 'RUN MEDICARE AI ANALYSIS',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // =================================================
                // ERROR
                // =================================================

                if (error != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // =================================================
                // AI RESULT
                // =================================================

                if (analysis != null) ...[
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Text(
                        'AI Assessment',
                        style: TextStyle(
                          color: navy,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _riskColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(19),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(23),
                      border: Border.all(
                        color: _riskColor().withValues(
                          alpha: 0.30,
                        ),
                      ),
                    ),
                    child: SelectableText(
                      analysis!,
                      style: const TextStyle(
                        color: Color(0xFF25384C),
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // =================================================
                // DISCLAIMER
                // =================================================

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E8),
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFB97800),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Medicare AI looks for patterns in monitoring data and patient-reported symptoms. It does not diagnose disease or guarantee future medical outcomes.',
                          style: TextStyle(
                            color: Color(0xFF795B24),
                            fontSize: 12,
                            height: 1.45,
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
}

// =============================================================
// COUNT CARD
// =============================================================

class _CountCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _CountCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5EBF2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0968D8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF082B5C),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// VITAL SUMMARY
// =============================================================

class _VitalSummary extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;

  const _VitalSummary({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 112,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFF0968D8),
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value $unit',
              style: const TextStyle(
                color: Color(0xFF082B5C),
                fontSize: 16,
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
// DAILY CHECK-IN
// =============================================================

class _LatestCheckInCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _LatestCheckInCard({
    required this.data,
  });

  String _text(String key) {
    final value = data[key];

    if (value == null ||
        value.toString().trim().isEmpty) {
      return '--';
    }

    return value.toString();
  }

  bool _bool(String key) {
    final value = data[key];

    if (value is bool) {
      return value;
    }

    return value.toString().toLowerCase() == 'true';
  }

  @override
  Widget build(BuildContext context) {
    final symptoms = <String>[];

    if (_bool('fatigue')) {
      symptoms.add('Fatigue');
    }

    if (_bool('dizziness')) {
      symptoms.add('Dizziness');
    }

    if (_bool('shortnessOfBreath')) {
      symptoms.add('Shortness of breath');
    }

    if (_bool('chestDiscomfort')) {
      symptoms.add('Chest discomfort');
    }

    if (_bool('headache')) {
      symptoms.add('Headache');
    }

    if (_bool('nausea')) {
      symptoms.add('Nausea');
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5EBF2),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.assignment_turned_in_outlined,
                color: Color(0xFF0968D8),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Latest Daily Check-In',
                  style: TextStyle(
                    color: Color(0xFF082B5C),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _CheckInLine(
            title: 'Mood',
            value: _text('mood'),
          ),

          _CheckInLine(
            title: 'Sleep',
            value:
                '${_text('sleepHours')} h • ${_text('sleepQuality')}',
          ),

          _CheckInLine(
            title: 'Stress',
            value:
                '${_text('stressLevel')} / 10',
          ),

          _CheckInLine(
            title: 'Pain',
            value:
                '${_text('painLevel')} / 10',
          ),

          _CheckInLine(
            title: 'Appetite',
            value: _text('appetite'),
          ),

          const SizedBox(height: 8),

          Text(
            symptoms.isEmpty
                ? 'No structured symptoms reported.'
                : symptoms.join(' • '),
            style: TextStyle(
              color: symptoms.isEmpty
                  ? Colors.green
                  : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          if (_text('symptoms') != '--') ...[
            const SizedBox(height: 9),
            Text(
              _text('symptoms'),
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================
// CHECK-IN LINE
// =============================================================

class _CheckInLine extends StatelessWidget {
  final String title;
  final String value;

  const _CheckInLine({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$title:',
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF20364D),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}