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
  final DatabaseService database =
      DatabaseService();

  final AiService aiService =
      AiService();

  bool loadingData = true;
  bool loadingAnalysis = false;

  String? error;
  String? analysis;

  Map<dynamic, dynamic>? latestVitals;

  List<Map<String, dynamic>> history = [];

  List<Map<String, dynamic>>
      dailyCheckIns = [];

  bool get isDemo =>
      AppMode.isDemo;

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
      loadingAnalysis = false;
      error = null;
      analysis = null;
    });

    if (isDemo) {
      _loadDemoData();
      return;
    }

    try {
      final results =
          await Future.wait([
        database.getLatestVitals(),

        database.getRecentHistory(
          limit: 30,
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
            results[0]
                as Map<dynamic, dynamic>?;

        history =
            results[1]
                as List<
                    Map<String, dynamic>>;

        dailyCheckIns =
            results[2]
                as List<
                    Map<String, dynamic>>;

        loadingData = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        loadingData = false;

        error =
            'Unable to load Medicare monitoring data.\n$e';
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
        Map<String, dynamic>.from(
          demoDaily,
        ),
      ];

      loadingData = false;
      error = null;
    });
  }

  // ============================================================
  // RUN EARLY DETECTION
  // ============================================================

  Future<void> _runDetection() async {
    if (loadingAnalysis) {
      return;
    }

    if (latestVitals == null &&
        history.isEmpty &&
        dailyCheckIns.isEmpty) {
      setState(() {
        error =
            'There is not enough monitoring data to analyze yet.';
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
      // NEVER CALL OPENAI.
      // =========================================================

      if (isDemo) {
        await Future<void>.delayed(
          const Duration(
            milliseconds: 850,
          ),
        );

        if (!mounted) {
          return;
        }

        setState(() {
          analysis =
              _buildDemoDetection();
        });

        return;
      }

      // =========================================================
      // REAL MODE
      // =========================================================

      final result =
          await aiService
              .analyzeComprehensive(
        latestVitals:
            latestVitals,

        history:
            history,

        dailyCheckIns:
            dailyCheckIns,
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
            'Early Detection analysis failed.\n$e';
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
  // LOCAL DEMO EARLY DETECTION
  // ============================================================

  String _buildDemoDetection() {
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
          latest[
              'bodyTemperature'],
        ) ??
        36.8;

    final roomTemperature =
        _toDouble(
          latest[
              'roomTemperature'],
        ) ??
        24.5;

    final humidity =
        _toDouble(
          latest['humidity'],
        ) ??
        55.0;

    return '''
MEDICARE EARLY DETECTION

DEMONSTRATION DATA

RISK LEVEL: ${demo['riskLevel'] ?? 'Low'}

TREND: ${demo['trend'] ?? 'Stable'}

CURRENT VALUES:

• Heart rate: $heartRate bpm
• SpO₂: $spo2 %
• Body temperature: ${temperature.toStringAsFixed(1)} °C
• Room temperature: ${roomTemperature.toStringAsFixed(1)} °C
• Humidity: ${humidity.toStringAsFixed(0)} %

MULTI-DAY PATTERN REVIEW:

${history.length} simulated monitoring records were reviewed.

Heart rate remains relatively stable with only small normal variation.

Oxygen saturation remains consistently high in the simulated dataset.

Body temperature does not show a repeated upward trend.

No repeated alert pattern appears in the simulated history.

The daily check-in does not report dizziness, shortness of breath, chest discomfort or meaningful pain.

ASSESSMENT:

${demo['summary'] ?? 'The simulated monitoring history appears stable.'}

RECOMMENDATION:

${demo['recommendation'] ?? 'Continue routine monitoring.'}

IMPORTANT:

This result uses SIMULATED DEMONSTRATION DATA.

MEDICARE Early Detection demonstrates risk-pattern monitoring and decision support.

It is not a diagnosis and must not be used as a replacement for professional healthcare assessment.
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

  bool _toBool(
    dynamic value,
  ) {
    if (value is bool) {
      return value;
    }

    if (value == 1 ||
        value == '1') {
      return true;
    }

    return value
            .toString()
            .toLowerCase() ==
        'true';
  }

  Color _riskColor() {
    final text =
        analysis
                ?.toUpperCase() ??
            '';

    if (text.contains(
      'RISK LEVEL: HIGH',
    )) {
      return Colors.red;
    }

    if (text.contains(
      'RISK LEVEL: MODERATE',
    )) {
      return Colors.orange;
    }

    if (text.contains(
      'RISK LEVEL: LOW',
    )) {
      return Colors.green;
    }

    return const Color(
      0xFF0968D8,
    );
  }

  String _valueOrDash(
    dynamic value,
  ) {
    if (value == null) {
      return '--';
    }

    return value.toString();
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

    final alert =
        _toBool(
      latest?['alert'],
    );

    return Scaffold(
      backgroundColor:
          background,

      appBar: AppBar(
        backgroundColor:
            background,

        surfaceTintColor:
            Colors.transparent,

        title: const Text(
          'Early Detection',
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
                  const EdgeInsets
                      .symmetric(
                vertical: 12,
              ),
              padding:
                  const EdgeInsets
                      .symmetric(
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
                    BorderRadius
                        .circular(
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
                    : _loadData,

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
                  _loadData,

              child:
                  ListView(
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  18,
                  12,
                  18,
                  35,
                ),

                children: [
                  if (isDemo)
                    Container(
                      padding:
                          const EdgeInsets
                              .all(
                        14,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFEDE7F6,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
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
                              'Explore risk-pattern monitoring using simulated multi-day data.',
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
                    'Monitoring Overview',
                    style:
                        TextStyle(
                      color: navy,
                      fontSize: 23,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    isDemo
                        ? 'Simulated monitoring data'
                        : 'Patient monitoring history',
                    style:
                        const TextStyle(
                      color: muted,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _SummaryCard(
                          icon:
                              Icons.history,
                          title:
                              'Records',
                          value:
                              '${history.length}',
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child:
                            _SummaryCard(
                          icon:
                              Icons.fact_check_outlined,
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
                        const EdgeInsets
                            .all(
                      18,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(
                        24,
                      ),
                    ),
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              alert
                                  ? Icons
                                      .warning_amber_rounded
                                  : Icons
                                      .monitor_heart_rounded,
                              color:
                                  alert
                                      ? Colors.red
                                      : blue,
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            const Text(
                              'Current Measurements',
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
                          height: 20,
                        ),

                        Row(
                          children: [
                            Expanded(
                              child:
                                  _VitalBox(
                                title:
                                    'Heart Rate',
                                value: heartRate ==
                                        null
                                    ? '--'
                                    : '$heartRate',
                                unit:
                                    'bpm',
                                icon:
                                    Icons.favorite,
                              ),
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            Expanded(
                              child:
                                  _VitalBox(
                                title:
                                    'SpO₂',
                                value: spo2 ==
                                        null
                                    ? '--'
                                    : '$spo2',
                                unit:
                                    '%',
                                icon:
                                    Icons.water_drop,
                              ),
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            Expanded(
                              child:
                                  _VitalBox(
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
                                icon:
                                    Icons.thermostat,
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

                  Container(
                    padding:
                        const EdgeInsets
                            .all(
                      18,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(
                        24,
                      ),
                    ),
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons
                                  .insights_rounded,
                              color:
                                  blue,
                            ),

                            SizedBox(
                              width: 10,
                            ),

                            Text(
                              'Trend Inputs',
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
                          height: 15,
                        ),

                        _InfoRow(
                          title:
                              'Monitoring records',
                          value:
                              '${history.length}',
                        ),

                        _InfoRow(
                          title:
                              'Daily check-ins',
                          value:
                              '${dailyCheckIns.length}',
                        ),

                        _InfoRow(
                          title:
                              'Latest alert',
                          value:
                              alert
                                  ? 'Detected'
                                  : 'None',
                        ),

                        _InfoRow(
                          title:
                              'ECG lead',
                          value:
                              _toBool(
                                latest?[
                                    'ecgLeadOff'],
                              )
                                  ? 'Disconnected'
                                  : 'Connected',
                        ),

                        _InfoRow(
                          title:
                              'Battery',
                          value:
                              '${_valueOrDash(latest?['batteryPercent'])} %',
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
                        ElevatedButton
                            .icon(
                      onPressed:
                          loadingAnalysis
                              ? null
                              : _runDetection,

                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            blue,
                        foregroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
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
                                  Icons
                                      .insights_rounded,
                                ),

                      label:
                          Text(
                        loadingAnalysis
                            ? 'ANALYZING PATTERNS...'
                            : isDemo
                                ? 'RUN DEMO EARLY DETECTION'
                                : 'RUN EARLY DETECTION',
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
                          const EdgeInsets
                              .all(
                        16,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFFFEEEE,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          18,
                        ),
                      ),
                      child:
                          Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
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
                          const EdgeInsets
                              .all(
                        18,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,
                        borderRadius:
                            BorderRadius
                                .circular(
                          24,
                        ),
                        border:
                            Border.all(
                          color:
                              _riskColor()
                                  .withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons
                                    .health_and_safety_outlined,
                                color:
                                    _riskColor(),
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              Text(
                                isDemo
                                    ? 'Demo Risk Assessment'
                                    : 'Risk Assessment',
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
                    'MEDICARE Early Detection provides monitoring and decision support only. It does not diagnose disease or replace professional medical assessment.',
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
// SUMMARY CARD
// ============================================================

class _SummaryCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryCard({
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
            width: 46,
            height: 46,
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
            width: 10,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF718096,
                    ),
                    fontSize: 11,
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
    );
  }
}

// ============================================================
// VITAL BOX
// ============================================================

class _VitalBox
    extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;

  const _VitalBox({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 8,
        vertical: 14,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF5F8FC,
        ),
        borderRadius:
            BorderRadius.circular(
          17,
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
            height: 7,
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
              fontSize: 10,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          FittedBox(
            child:
                Text(
              '$value $unit',
              style:
                  const TextStyle(
                color:
                    Color(
                  0xFF082B5C,
                ),
                fontSize: 17,
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

class _InfoRow
    extends StatelessWidget {
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
        vertical: 6,
      ),
      child:
          Row(
        children: [
          Expanded(
            child:
                Text(
              title,
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