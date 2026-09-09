import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import '../services/app_mode.dart';
import '../services/database_service.dart';
import '../services/demo_data_service.dart';

class AiAnalysisScreen extends StatefulWidget {
  const AiAnalysisScreen({super.key});

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen> {
  final DatabaseService database = DatabaseService();
  final AiService aiService = AiService();

  bool loadingData = true;
  bool loadingAnalysis = false;

  String? error;
  String? analysis;

  Map<dynamic, dynamic>? latestVitals;

  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> dailyCheckIns = [];

  bool get isDemo => AppMode.isDemo;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadPatientData() async {
    setState(() {
      loadingData = true;
      error = null;
      analysis = null;
    });

    // ------------------------------------------------------------
    // DEMO MODE
    // ------------------------------------------------------------

    if (isDemo) {
      _loadDemoData();
      return;
    }

    // ------------------------------------------------------------
    // REAL PATIENT MODE
    // ------------------------------------------------------------

    try {
      final results = await Future.wait([
        database.getLatestVitals(),
        database.getRecentHistory(
          limit: 20,
        ),
        database.getRecentDailyCheckIns(
          limit: 14,
        ),
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
  // DEMO DATA
  // ============================================================

  void _loadDemoData() {
    final demoVitals =
        DemoDataService.currentVitals;

    final demoHistory =
        DemoDataService.history;

    final demoDaily =
        DemoDataService.dailyCheckIn;

    final normalizedDaily =
        <String, dynamic>{
      'mood':
          demoDaily['mood'] ??
          demoDaily['feeling'] ??
          'Good',

      'sleepHours':
          demoDaily['sleepHours'] ??
          7.5,

      'sleepQuality':
          demoDaily['sleepQuality'] ??
          'Good',

      'stressLevel':
          demoDaily['stressLevel'] ??
          2,

      'painLevel':
          demoDaily['painLevel'] ??
          0,

      'appetite':
          demoDaily['appetite'] ??
          'Normal',

      'fatigue':
          demoDaily['fatigue'] ??
          'Mild',

      'dizziness':
          demoDaily['dizziness'] ??
          false,

      'shortnessOfBreath':
          demoDaily['shortnessOfBreath'] ??
          false,

      'chestDiscomfort':
          demoDaily['chestDiscomfort'] ??
          false,

      'headache':
          demoDaily['headache'] ??
          false,

      'nausea':
          demoDaily['nausea'] ??
          false,

      'symptoms':
          demoDaily['symptoms'] ??
          '',

      'notes':
          demoDaily['notes'] ??
          'Demonstration patient check-in.',

      'timestamp':
          demoDaily['timestamp'] ??
          DateTime.now().millisecondsSinceEpoch,
    };

    if (!mounted) {
      return;
    }

    setState(() {
      latestVitals =
          Map<dynamic, dynamic>.from(
        demoVitals,
      );

      history =
          demoHistory
              .map(
                (item) =>
                    Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList();

      dailyCheckIns = [
        normalizedDaily,
      ];

      loadingData = false;
      error = null;
    });
  }

  // ============================================================
  // RUN ANALYSIS
  // ============================================================

  Future<void> _runAnalysis() async {
    if (loadingAnalysis) {
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
      loadingAnalysis = true;
      error = null;
      analysis = null;
    });

    try {
      // =========================================================
      // DEMO MODE
      //
      // NEVER CALL OPENAI HERE.
      // =========================================================

      if (isDemo) {
        await Future<void>.delayed(
          const Duration(
            milliseconds: 800,
          ),
        );

        if (!mounted) {
          return;
        }

        setState(() {
          analysis = _buildDemoAnalysis();
        });

        return;
      }

      // =========================================================
      // REAL PATIENT MODE
      // =========================================================

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
        error =
            'AI analysis failed.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          loadingAnalysis = false;
        });
      }
    }
  }

  // ============================================================
  // LOCAL DEMO AI ANALYSIS
  // ============================================================

  String _buildDemoAnalysis() {
    final demo =
        DemoDataService.earlyDetection;

    final latest =
        latestVitals ?? {};

    final heartRate =
        _toInt(
          latest['heartRate'],
        ) ??
        78;

    final spo2 =
        _toInt(
          latest['spo2'],
        ) ??
        98;

    final temperature =
        _toDouble(
          latest['bodyTemperature'],
        ) ??
        36.8;

    final roomTemperature =
        _toDouble(
          latest['roomTemperature'],
        ) ??
        24.5;

    final humidity =
        _toDouble(
          latest['humidity'],
        ) ??
        55.0;

    return '''
DEMONSTRATION DATA

RISK LEVEL:
${demo['riskLevel'] ?? 'Low'}

TREND:
${demo['trend'] ?? 'Stable'}

CURRENT MONITORING SUMMARY:

• Heart rate: $heartRate bpm
• SpO₂: $spo2 %
• Body temperature: ${temperature.toStringAsFixed(1)} °C
• Room temperature: ${roomTemperature.toStringAsFixed(1)} °C
• Humidity: ${humidity.toStringAsFixed(0)} %
• ECG signal available
• No urgent simulated symptoms reported

PATTERN REVIEW:

The simulated measurements remain generally stable across the demonstration history.

Heart-rate values show only small variations across the seven simulated checkups.

Oxygen saturation remains stable in the upper range.

Body temperature does not show a significant rising trend.

The simulated daily check-in reports good sleep, low stress, no pain, no dizziness and no shortness of breath.

ASSESSMENT:

${demo['summary'] ?? 'The simulated monitoring history appears stable.'}

RECOMMENDATION:

${demo['recommendation'] ?? 'Continue routine monitoring.'}

IMPORTANT:

This result uses SIMULATED DEMONSTRATION DATA.

It demonstrates how Medicare can combine measurements, monitoring history and patient check-ins to provide AI-assisted decision support.

It is not based on a real patient and is not a medical diagnosis.
''';
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int? _toInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  Color _riskColor() {
    final text =
        analysis
            ?.toUpperCase() ??
        '';

    if (text.contains(
      'RISK LEVEL:\nHIGH',
    )) {
      return Colors.red;
    }

    if (text.contains(
      'RISK LEVEL:\nMODERATE',
    )) {
      return Colors.orange;
    }

    if (text.contains(
      'RISK LEVEL:\nLOW',
    )) {
      return Colors.green;
    }

    return const Color(
      0xFF0968D8,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    const navy =
        Color(0xFF082B5C);

    const blue =
        Color(0xFF0968D8);

    const background =
        Color(0xFFF5F8FC);

    const muted =
        Color(0xFF718096);

    final latest =
        latestVitals;

    final heartRate =
        _toInt(
      latest?['heartRate'],
    );

    final spo2 =
        _toInt(
      latest?['spo2'],
    );

    final temperature =
        _toDouble(
      latest?[
          'bodyTemperature'],
    );

    final latestCheckIn =
        dailyCheckIns.isNotEmpty
            ? dailyCheckIns.first
            : null;

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor:
            background,
        surfaceTintColor:
            Colors.transparent,

        title: const Text(
          'AI Analysis',
          style: TextStyle(
            color: navy,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        actions: [
          if (isDemo)
            Container(
              margin:
                  const EdgeInsets.symmetric(
                vertical: 12,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              alignment:
                  Alignment.center,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFEDE7F6,
                ),
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child:
                  const Text(
                'DEMO',
                style:
                    TextStyle(
                  color:
                      Color(
                    0xFF673AB7,
                  ),
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

          IconButton(
            onPressed:
                loadingData
                    ? null
                    : _loadPatientData,
            icon:
                const Icon(
              Icons.refresh_rounded,
            ),
          ),

          const SizedBox(
            width: 8,
          ),
        ],
      ),

      body: loadingData
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh:
                  _loadPatientData,

              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  35,
                ),

                children: [
                  if (isDemo)
                    Container(
                      padding:
                          const EdgeInsets.all(
                        14,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFEDE7F6,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),
                      child:
                          const Row(
                        children: [
                          Icon(
                            Icons
                                .science_outlined,
                            color:
                                Color(
                              0xFF673AB7,
                            ),
                          ),

                          SizedBox(
                            width: 10,
                          ),

                          Expanded(
                            child:
                                Text(
                              'Demo Mode uses simulated patient measurements. OpenAI is not called.',
                              style:
                                  TextStyle(
                                color:
                                    Color(
                                  0xFF512DA8,
                                ),
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (isDemo)
                    const SizedBox(
                      height: 18,
                    ),

                  const Text(
                    'Data Available',
                    style:
                        TextStyle(
                      color: navy,
                      fontSize: 23,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _CountCard(
                          icon: Icons
                              .monitor_heart_outlined,
                          title:
                              'Checkups',
                          value:
                              '${history.length}',
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child:
                            _CountCard(
                          icon: Icons
                              .check_box_outlined,
                          title:
                              'Check-Ins',
                          value:
                              '${dailyCheckIns.length}',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  Container(
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                    ),
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons
                                  .monitor_heart_rounded,
                              color:
                                  blue,
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child:
                                  Text(
                                isDemo
                                    ? 'Simulated Measurements'
                                    : 'Latest Measurements',
                                style:
                                    const TextStyle(
                                  color:
                                      navy,
                                  fontSize:
                                      20,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        Row(
                          children: [
                            Expanded(
                              child:
                                  _VitalCard(
                                icon: Icons
                                    .favorite_rounded,
                                title:
                                    'Heart Rate',
                                value: heartRate ==
                                        null
                                    ? '--'
                                    : '$heartRate',
                                unit:
                                    'bpm',
                              ),
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            Expanded(
                              child:
                                  _VitalCard(
                                icon: Icons
                                    .water_drop_rounded,
                                title:
                                    'SpO₂',
                                value: spo2 ==
                                        null
                                    ? '--'
                                    : '$spo2',
                                unit:
                                    '%',
                              ),
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            Expanded(
                              child:
                                  _VitalCard(
                                icon: Icons
                                    .thermostat_rounded,
                                title:
                                    'Temp',
                                value: temperature ==
                                        null
                                    ? '--'
                                    : temperature
                                        .toStringAsFixed(
                                          1,
                                        ),
                                unit:
                                    '°C',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  if (latestCheckIn != null)
                    Container(
                      padding:
                          const EdgeInsets.all(
                        18,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          24,
                        ),
                      ),
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons
                                    .check_box_outlined,
                                color:
                                    blue,
                              ),

                              SizedBox(
                                width: 10,
                              ),

                              Text(
                                'Latest Daily Check-In',
                                style:
                                    TextStyle(
                                  color:
                                      navy,
                                  fontSize:
                                      19,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          _InfoRow(
                            title:
                                'Mood',
                            value:
                                '${latestCheckIn['mood'] ?? 'Not available'}',
                          ),

                          _InfoRow(
                            title:
                                'Sleep',
                            value:
                                '${latestCheckIn['sleepHours'] ?? '--'} h',
                          ),

                          _InfoRow(
                            title:
                                'Stress',
                            value:
                                '${latestCheckIn['stressLevel'] ?? '--'} / 10',
                          ),

                          _InfoRow(
                            title:
                                'Pain',
                            value:
                                '${latestCheckIn['painLevel'] ?? '--'} / 10',
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(
                    height: 20,
                  ),

                  SizedBox(
                    height: 58,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          loadingAnalysis
                              ? null
                              : _runAnalysis,

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            blue,
                        foregroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                        ),
                      ),

                      icon:
                          loadingAnalysis
                              ? const SizedBox(
                                  width:
                                      22,
                                  height:
                                      22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.auto_awesome,
                                ),

                      label:
                          Text(
                        loadingAnalysis
                            ? 'ANALYZING...'
                            : isDemo
                                ? 'RUN DEMO AI ANALYSIS'
                                : 'RUN MEDICARE AI ANALYSIS',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  if (error != null) ...[
                    const SizedBox(
                      height: 18,
                    ),

                    Container(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFFFEEEE,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),
                      child:
                          Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons
                                .error_outline,
                            color:
                                Colors.red,
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Expanded(
                            child:
                                Text(
                              error!,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (analysis != null) ...[
                    const SizedBox(
                      height: 18,
                    ),

                    Container(
                      padding:
                          const EdgeInsets.all(
                        18,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          24,
                        ),
                        border:
                            Border.all(
                          color:
                              _riskColor()
                                  .withValues(
                            alpha:
                                0.35,
                          ),
                        ),
                      ),
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons
                                    .psychology_alt_outlined,
                                color:
                                    _riskColor(),
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              Text(
                                isDemo
                                    ? 'Demo Analysis'
                                    : 'AI Analysis Result',
                                style:
                                    const TextStyle(
                                  color:
                                      navy,
                                  fontSize:
                                      19,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          SelectableText(
                            analysis!,
                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF26384F,
                              ),
                              height:
                                  1.55,
                              fontSize:
                                  14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 18,
                  ),

                  const Text(
                    'Medicare provides monitoring and decision support only. It does not replace professional medical diagnosis or treatment.',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          muted,
                      fontSize:
                          11,
                      height:
                          1.4,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ============================================================
// COUNT CARD
// ============================================================

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
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child:
          Row(
        children: [
          Container(
            width:
                48,
            height:
                48,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFEAF4FF,
              ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child:
                Icon(
              icon,
              color:
                  const Color(
                0xFF0968D8,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF718096,
                    ),
                    fontSize:
                        12,
                  ),
                ),

                Text(
                  value,
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF082B5C,
                    ),
                    fontSize:
                        24,
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

// ============================================================
// VITAL CARD
// ============================================================

class _VitalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;

  const _VitalCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 16,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF5F8FC,
        ),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child:
          Column(
        children: [
          Icon(
            icon,
            color:
                const Color(
              0xFF0968D8,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            title,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Color(
                0xFF718096,
              ),
              fontSize:
                  11,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          FittedBox(
            fit:
                BoxFit.scaleDown,
            child:
                Text(
              '$value $unit',
              style:
                  const TextStyle(
                color:
                    Color(
                  0xFF082B5C,
                ),
                fontSize:
                    18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INFO ROW
// ============================================================

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child:
          Row(
        children: [
          Expanded(
            child:
                Text(
              '$title:',
              style:
                  const TextStyle(
                color:
                    Color(
                  0xFF718096,
                ),
              ),
            ),
          ),

          Text(
            value,
            style:
                const TextStyle(
              color:
                  Color(
                0xFF12263F,
              ),
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}