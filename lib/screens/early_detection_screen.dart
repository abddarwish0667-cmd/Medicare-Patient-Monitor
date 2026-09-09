import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import '../services/app_mode.dart';
import '../services/database_service.dart';
import '../services/demo_data_service.dart';

class EarlyDetectionScreen extends StatefulWidget {
  const EarlyDetectionScreen({super.key});

  @override
  State<EarlyDetectionScreen> createState() =>
      _EarlyDetectionScreenState();
}

class _EarlyDetectionScreenState
    extends State<EarlyDetectionScreen> {
  final DatabaseService database = DatabaseService();
  final AiService aiService = AiService();

  bool loadingData = true;
  bool analyzing = false;

  String? error;
  String? result;

  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> dailyCheckIns = [];

  bool get isDemo => AppMode.isDemo;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    setState(() {
      loadingData = true;
      error = null;
      result = null;
    });

    if (isDemo) {
      _loadDemoData();
      return;
    }

    try {
      final results = await Future.wait([
        database.getRecentHistory(
          limit: 20,
        ),
        database.getRecentDailyCheckIns(
          limit: 14,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        history = results[0];
        dailyCheckIns = results[1];
        loadingData = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingData = false;
        error =
            'Unable to load monitoring history.\n$e';
      });
    }
  }

  // ============================================================
  // LOAD DEMO DATA
  // ============================================================

  void _loadDemoData() {
    final demoHistory = DemoDataService.history;
    final checkIn = DemoDataService.dailyCheckIn;

    final normalizedCheckIn = <String, dynamic>{
      'mood': checkIn['feeling'] ?? 'Good',
      'sleepHours': checkIn['sleepHours'] ?? 7.5,
      'sleepQuality':
          checkIn['sleepQuality'] ?? 'Good',
      'stressLevel': 2,
      'painLevel':
          checkIn['pain'] == true ? 3 : 0,
      'appetite': 'Normal',
      'fatigue':
          checkIn['fatigue']
                  ?.toString()
                  .toLowerCase() !=
              'no',
      'dizziness':
          checkIn['dizziness'] ?? false,
      'shortnessOfBreath':
          checkIn['shortnessOfBreath'] ?? false,
      'chestDiscomfort': false,
      'headache': false,
      'nausea': false,
      'symptoms': '',
      'notes':
          checkIn['notes'] ??
              'Demonstration check-in.',
      'timestamp': checkIn['timestamp'],
    };

    if (!mounted) return;

    setState(() {
      history = demoHistory
          .map(
            (item) =>
                Map<String, dynamic>.from(item),
          )
          .toList();

      dailyCheckIns = [
        normalizedCheckIn,
      ];

      loadingData = false;
      error = null;
    });
  }

  // ============================================================
  // RUN EARLY DETECTION
  // ============================================================

  Future<void> _analyze() async {
    if (analyzing) return;

    if (history.isEmpty &&
        dailyCheckIns.isEmpty) {
      setState(() {
        error =
            'There is not enough historical data for early detection yet.';
      });

      return;
    }

    setState(() {
      analyzing = true;
      error = null;
      result = null;
    });

    try {
      // ========================================================
      // DEMO MODE
      // ========================================================

      if (isDemo) {
        await Future<void>.delayed(
          const Duration(milliseconds: 900),
        );

        if (!mounted) return;

        setState(() {
          result = _buildDemoResult();
        });

        return;
      }

      // ========================================================
      // REAL MODE
      // ========================================================

      final response =
          await aiService.analyzeEarlyDetection(
        history: history,
        dailyCheckIns: dailyCheckIns,
      );

      if (!mounted) return;

      setState(() {
        result = response;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error =
            'Early Detection analysis failed.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          analyzing = false;
        });
      }
    }
  }

  // ============================================================
  // DEMO EARLY-DETECTION RESULT
  // ============================================================

  String _buildDemoResult() {
    final demo = DemoDataService.earlyDetection;

    return '''
RISK LEVEL: ${demo['riskLevel'] ?? 'Low'}

TREND: ${demo['trend'] ?? 'Stable'}

MONITORING PERIOD:

7 simulated daily measurements were reviewed together with the demonstration Daily Check-In.

VITAL-SIGN PATTERNS:

• Heart rate remains generally stable across the simulated monitoring period.

• SpO₂ remains stable without a persistent downward pattern.

• Body temperature remains stable without a meaningful rising trend.

• No repeated alert pattern is present in the demonstration history.

PATIENT-REPORTED WELLNESS:

• General feeling: Good
• Sleep: 7.5 hours
• Sleep quality: Good
• Pain: Not reported
• Dizziness: Not reported
• Shortness of breath: Not reported
• Fatigue: Mild

TREND ASSESSMENT:

${demo['summary'] ?? 'The simulated monitoring data shows no major worsening trend.'}

EARLY-DETECTION INTERPRETATION:

The demonstration dataset does not show a persistent combination of worsening vital signs and worsening patient-reported symptoms.

The current simulated risk pattern is therefore categorized as LOW.

RECOMMENDATION:

${demo['recommendation'] ?? 'Continue routine monitoring.'}

IMPORTANT:

This result is generated from SIMULATED DEMONSTRATION DATA.

It does not predict a disease, diagnose a medical condition, or guarantee that a medical event will or will not occur.

MEDICARE Early Detection is intended to demonstrate risk-pattern monitoring and decision support.
''';
  }

  // ============================================================
  // RISK HELPERS
  // ============================================================

  String _riskLabel() {
    final text =
        result?.toUpperCase() ?? '';

    if (text.contains(
      'RISK LEVEL: HIGH',
    )) {
      return 'HIGH';
    }

    if (text.contains(
      'RISK LEVEL: MODERATE',
    )) {
      return 'MODERATE';
    }

    if (text.contains(
      'RISK LEVEL: LOW',
    )) {
      return 'LOW';
    }

    return 'INSUFFICIENT DATA';
  }

  Color _riskColor() {
    switch (_riskLabel()) {
      case 'HIGH':
        return Colors.red;

      case 'MODERATE':
        return Colors.orange;

      case 'LOW':
        return Colors.green;

      default:
        return Colors.blueGrey;
    }
  }

  IconData _riskIcon() {
    switch (_riskLabel()) {
      case 'HIGH':
        return Icons.warning_amber_rounded;

      case 'MODERATE':
        return Icons.trending_up_rounded;

      case 'LOW':
        return Icons.check_circle_outline_rounded;

      default:
        return Icons.help_outline_rounded;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF082B5C);
    const blue = Color(0xFF0968D8);
    const purple = Color(0xFF673AB7);
    const background = Color(0xFFF5F8FC);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Early Detection',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isDemo)
            Container(
              margin: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'DEMO',
                  style: TextStyle(
                    color: purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          IconButton(
            tooltip: 'Refresh data',
            onPressed:
                loadingData ? null : _loadData,
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
                // DEMO WARNING
                // =================================================

                if (isDemo) ...[
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE7F6),
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color:
                            const Color(0xFFD1C4E9),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.science_outlined,
                          color: purple,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Demonstration Mode\nEarly Detection is using simulated monitoring history and a simulated Daily Check-In. No real patient data is being analyzed.',
                            style: TextStyle(
                              color:
                                  Color(0xFF512DA8),
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                ],

                // =================================================
                // HEADER
                // =================================================

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                      colors: isDemo
                          ? const [
                              Color(0xFF4527A0),
                              Color(0xFF7E57C2),
                            ]
                          : const [
                              navy,
                              blue,
                            ],
                    ),
                    borderRadius:
                        BorderRadius.circular(27),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insights_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              isDemo
                                  ? 'Early Detection Demo'
                                  : 'Early Detection',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              isDemo
                                  ? 'Explore risk-pattern monitoring using simulated multi-day data.'
                                  : 'Looks for worsening patterns across multiple days.',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white70,
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

                Text(
                  isDemo
                      ? 'Demo History Available'
                      : 'History Available',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _HistoryCountCard(
                        icon: Icons
                            .monitor_heart_outlined,
                        title: 'Checkups',
                        value: '${history.length}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HistoryCountCard(
                        icon: Icons
                            .assignment_turned_in_outlined,
                        title: 'Daily Check-Ins',
                        value:
                            '${dailyCheckIns.length}',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // =================================================
                // EXPLANATION
                // =================================================

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(22),
                    border: Border.all(
                      color:
                          const Color(0xFFE5EBF2),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timeline_rounded,
                            color: blue,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'What Medicare checks',
                            style: TextStyle(
                              color: navy,
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 15),

                      _DetectionPoint(
                        text:
                            'Repeated changes in heart rate, SpO₂ and body temperature.',
                      ),

                      _DetectionPoint(
                        text:
                            'Repeated alerts across multiple checkups.',
                      ),

                      _DetectionPoint(
                        text:
                            'Worsening sleep, stress, fatigue or pain.',
                      ),

                      _DetectionPoint(
                        text:
                            'Repeated dizziness, shortness of breath or chest discomfort.',
                      ),

                      _DetectionPoint(
                        text:
                            'Patterns where sensor measurements and patient symptoms worsen together.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // ANALYZE BUTTON
                // =================================================

                SizedBox(
                  height: 59,
                  child: ElevatedButton.icon(
                    onPressed:
                        analyzing ? null : _analyze,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          isDemo ? purple : blue,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),
                    ),
                    icon: analyzing
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
                            Icons.analytics_rounded,
                          ),
                    label: Text(
                      analyzing
                          ? 'ANALYZING TRENDS...'
                          : isDemo
                              ? 'RUN DEMO EARLY DETECTION'
                              : 'RUN EARLY DETECTION',
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
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
                    padding: const EdgeInsets.all(
                      16,
                    ),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFFFF0F0),
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons
                              .error_outline_rounded,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            error!,
                            style:
                                const TextStyle(
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
                // RESULT
                // =================================================

                if (result != null) ...[
                  const SizedBox(height: 22),

                  Text(
                    isDemo
                        ? 'Demo Trend Assessment'
                        : 'Trend Assessment',
                    style: const TextStyle(
                      color: navy,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(
                      18,
                    ),
                    decoration: BoxDecoration(
                      color: _riskColor()
                          .withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: _riskColor()
                            .withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _riskIcon(),
                          color: _riskColor(),
                          size: 34,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                isDemo
                                    ? 'Simulated Risk Pattern'
                                    : 'Risk Pattern',
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.blueGrey,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                _riskLabel(),
                                style: TextStyle(
                                  color:
                                      _riskColor(),
                                  fontSize: 22,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      19,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(23),
                      border: Border.all(
                        color:
                            const Color(0xFFE5EBF2),
                      ),
                    ),
                    child: SelectableText(
                      result!,
                      style: const TextStyle(
                        color:
                            Color(0xFF25384C),
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
                    color:
                        const Color(0xFFFFF8E8),
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color:
                            Color(0xFFB97800),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isDemo
                              ? 'This demonstration uses simulated monitoring data only. The displayed risk pattern does not describe a real person and must not be used for medical decision-making.'
                              : 'Early Detection looks for concerning trends in available monitoring data. It does not predict a specific disease, provide a diagnosis, or guarantee that a medical event will occur.',
                          style: const TextStyle(
                            color:
                                Color(0xFF795B24),
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

class _HistoryCountCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _HistoryCountCard({
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
        borderRadius:
            BorderRadius.circular(18),
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
              color:
                  const Color(0xFFEAF4FF),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color:
                  const Color(0xFF0968D8),
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
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color:
                        Color(0xFF082B5C),
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
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
// DETECTION POINT
// =============================================================

class _DetectionPoint extends StatelessWidget {
  final String text;

  const _DetectionPoint({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons
                  .check_circle_outline_rounded,
              color:
                  Color(0xFF0968D8),
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color:
                    Color(0xFF40556C),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}