import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../services/app_mode.dart';
import '../services/demo_data_service.dart';

class EcgScreen extends StatefulWidget {
  const EcgScreen({super.key});

  @override
  State<EcgScreen> createState() => _EcgScreenState();
}

class _EcgScreenState extends State<EcgScreen> {
  final DatabaseService database = DatabaseService();

  DatabaseReference? ecgRef;

  StreamSubscription<DatabaseEvent>? latestSubscription;

  bool loading = true;
  bool loadingWaveform = false;

  String? error;

  String? recordingId;

  int? timestamp;
  int sampleRate = 250;
  int sampleCount = 0;
  int average = 0;

  bool leadOff = true;

  List<double> samples = [];

  @override
  void initState() {
    super.initState();

    if (AppMode.isDemo) {
      _loadDemoEcg();
    } else {
      _initializeEcg();
    }
  }

  @override
  void dispose() {
    latestSubscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // DEMO ECG
  // ============================================================

  void _loadDemoEcg() {
    final demoSamples = DemoDataService.generateEcg(
      samples: 1000,
    );

    setState(() {
      recordingId = 'DEMO-ECG-001';

      samples = demoSamples;

      sampleRate = 250;
      sampleCount = demoSamples.length;

      timestamp =
          DateTime.now().millisecondsSinceEpoch;

      if (demoSamples.isNotEmpty) {
        final sum = demoSamples.fold<double>(
          0,
          (total, value) => total + value,
        );

        average =
            (sum / demoSamples.length * 1000)
                .round();
      } else {
        average = 0;
      }

      leadOff = false;

      loading = false;
      loadingWaveform = false;
      error = null;
    });
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initializeEcg() async {
    try {
      final ref = await database.getEcgRef();

      if (!mounted) return;

      ecgRef = ref;

      latestSubscription?.cancel();

      latestSubscription =
          ref.child('latest').onValue.listen(
        (event) {
          _handleLatestSnapshot(
            event.snapshot,
          );
        },
        onError: (Object e) {
          if (!mounted) return;

          setState(() {
            error =
                'Unable to receive ECG data.\n$e';
            loading = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  // ============================================================
  // HANDLE LATEST SNAPSHOT
  // ============================================================

  Future<void> _handleLatestSnapshot(
    DataSnapshot snapshot,
  ) async {
    final raw = snapshot.value;

    if (raw == null || raw is! Map) {
      if (!mounted) return;

      setState(() {
        loading = false;
        loadingWaveform = false;

        recordingId = null;
        samples = [];
        sampleCount = 0;
        timestamp = null;
        average = 0;
        leadOff = true;
      });

      return;
    }

    final latest =
        Map<dynamic, dynamic>.from(raw);

    final newRecordingId =
        latest['recordingId']
            ?.toString()
            .trim();

    if (newRecordingId == null ||
        newRecordingId.isEmpty) {
      if (!mounted) return;

      setState(() {
        loading = false;
        loadingWaveform = false;
        recordingId = null;
        samples = [];
      });

      return;
    }

    timestamp = _toInt(
      latest['timestamp'],
    );

    sampleRate =
        _toInt(
          latest['sampleRate'],
        ) ??
        250;

    sampleCount =
        _toInt(
          latest['sampleCount'],
        ) ??
        0;

    average =
        _toInt(
          latest['average'],
        ) ??
        0;

    leadOff = _toBool(
      latest['leadOff'],
    );

    if (newRecordingId == recordingId &&
        samples.isNotEmpty) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      return;
    }

    recordingId = newRecordingId;

    await _loadRecording(
      newRecordingId,
    );
  }

  // ============================================================
  // LOAD WAVEFORM
  // ============================================================

  Future<void> _loadRecording(
    String id,
  ) async {
    final ref = ecgRef;

    if (ref == null) return;

    if (mounted) {
      setState(() {
        loading = false;
        loadingWaveform = true;
        error = null;
      });
    }

    try {
      final recordingSnapshot =
          await ref
              .child(
                'recordings/$id',
              )
              .get();

      if (!recordingSnapshot.exists ||
          recordingSnapshot.value is! Map) {
        throw Exception(
          'The ECG recording could not be found.',
        );
      }

      final recording =
          Map<dynamic, dynamic>.from(
        recordingSnapshot.value as Map,
      );

      // ========================================================
      // META
      // ========================================================

      if (recording['meta'] is Map) {
        final meta =
            Map<dynamic, dynamic>.from(
          recording['meta'] as Map,
        );

        timestamp =
            _toInt(
              meta['timestamp'],
            ) ??
            timestamp;

        sampleRate =
            _toInt(
              meta['sampleRate'],
            ) ??
            sampleRate;

        sampleCount =
            _toInt(
              meta['sampleCount'],
            ) ??
            sampleCount;

        average =
            _toInt(
              meta['average'],
            ) ??
            average;

        leadOff = _toBool(
          meta['leadOff'],
        );
      }

      // ========================================================
      // SAMPLES
      // ========================================================

      final waveform =
          <int, double>{};

      if (recording['samples'] is Map) {
        final chunks =
            Map<dynamic, dynamic>.from(
          recording['samples'] as Map,
        );

        for (final chunkEntry
            in chunks.entries) {
          final chunkValue =
              chunkEntry.value;

          if (chunkValue is! Map) {
            continue;
          }

          final chunk =
              Map<dynamic, dynamic>.from(
            chunkValue,
          );

          for (final sampleEntry
              in chunk.entries) {
            final index =
                int.tryParse(
              sampleEntry.key.toString(),
            );

            final value =
                double.tryParse(
              sampleEntry.value.toString(),
            );

            if (index == null ||
                value == null) {
              continue;
            }

            waveform[index] = value;
          }
        }
      }

      final indexes =
          waveform.keys.toList()
            ..sort();

      final orderedSamples =
          <double>[];

      for (final index in indexes) {
        final value =
            waveform[index];

        if (value != null) {
          orderedSamples.add(
            value,
          );
        }
      }

      if (!mounted) return;

      setState(() {
        samples = orderedSamples;

        if (samples.isNotEmpty) {
          sampleCount =
              samples.length;
        }

        loadingWaveform = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error =
            'Unable to load ECG waveform.\n$e';

        loadingWaveform = false;
      });
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    if (AppMode.isDemo) {
      await Future<void>.delayed(
        const Duration(
          milliseconds: 350,
        ),
      );

      if (!mounted) return;

      _loadDemoEcg();
      return;
    }

    final ref = ecgRef;

    if (ref == null) {
      await _initializeEcg();
      return;
    }

    try {
      final snapshot =
          await ref
              .child('latest')
              .get();

      await _handleLatestSnapshot(
        snapshot,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error =
            'Unable to refresh ECG.\n$e';
      });
    }
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

  String _recordingTimeText() {
    final value = timestamp;

    if (value == null ||
        value <= 0) {
      return 'Unknown time';
    }

    try {
      final milliseconds =
          value > 100000000000
              ? value
              : value * 1000;

      final date =
          DateTime
              .fromMillisecondsSinceEpoch(
        milliseconds,
      ).toLocal();

      final day =
          date.day
              .toString()
              .padLeft(
        2,
        '0',
      );

      final month =
          date.month
              .toString()
              .padLeft(
        2,
        '0',
      );

      final hour =
          date.hour
              .toString()
              .padLeft(
        2,
        '0',
      );

      final minute =
          date.minute
              .toString()
              .padLeft(
        2,
        '0',
      );

      final second =
          date.second
              .toString()
              .padLeft(
        2,
        '0',
      );

      return '$day/$month/${date.year} • '
          '$hour:$minute:$second';
    } catch (_) {
      return 'Unknown time';
    }
  }

  String _durationText() {
    if (sampleRate <= 0 ||
        sampleCount <= 0) {
      return '--';
    }

    final duration =
        sampleCount / sampleRate;

    return '${duration.toStringAsFixed(1)} s';
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

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor:
            Colors.transparent,
        title: const Text(
          'ECG Monitor',
          style: TextStyle(
            color: navy,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          if (AppMode.isDemo)
            Container(
              margin:
                  const EdgeInsets
                      .symmetric(
                vertical: 12,
              ),
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 10,
                vertical: 5,
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
                  20,
                ),
              ),
              child: const Center(
                child: Text(
                  'DEMO',
                  style:
                      TextStyle(
                    color:
                        Color(
                      0xFF673AB7,
                    ),
                    fontSize:
                        10,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
              ),
            ),

          IconButton(
            tooltip:
                'Refresh ECG',
            onPressed:
                _refresh,
            icon: const Icon(
              Icons
                  .refresh_rounded,
            ),
          ),
        ],
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  35,
                ),
                children: [
                  if (AppMode.isDemo) ...[
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
                          17,
                        ),
                        border:
                            Border.all(
                          color:
                              const Color(
                            0xFFD1C4E9,
                          ),
                        ),
                      ),
                      child:
                          const Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
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
                            width:
                                10,
                          ),
                          Expanded(
                            child:
                                Text(
                              'Demonstration ECG\nThis waveform is simulated and is not a real patient ECG.',
                              style:
                                  TextStyle(
                                color:
                                    Color(
                                  0xFF512DA8,
                                ),
                                fontSize:
                                    12,
                                height:
                                    1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),
                  ],

                  Container(
                    padding:
                        const EdgeInsets
                            .all(
                      21,
                    ),
                    decoration:
                        BoxDecoration(
                      gradient:
                          const LinearGradient(
                        begin:
                            Alignment
                                .topLeft,
                        end:
                            Alignment
                                .bottomRight,
                        colors: [
                          navy,
                          blue,
                        ],
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        26,
                      ),
                    ),
                    child:
                        Row(
                      children: [
                        Container(
                          width:
                              57,
                          height:
                              57,
                          decoration:
                              BoxDecoration(
                            color: Colors
                                .white
                                .withValues(
                              alpha:
                                  0.14,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              17,
                            ),
                          ),
                          child:
                              const Icon(
                            Icons
                                .monitor_heart_rounded,
                            color:
                                Colors.white,
                            size:
                                34,
                          ),
                        ),

                        const SizedBox(
                          width:
                              15,
                        ),

                        Expanded(
                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Text(
                                'ECG Recording',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize:
                                      21,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height:
                                    4,
                              ),

                              Text(
                                AppMode.isDemo
                                    ? 'Simulated ECG waveform for app demonstration'
                                    : 'AD8232 cardiac electrical signal',
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white70,
                                  fontSize:
                                      12,
                                ),
                              ),
                            ],
                          ),
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
                      17,
                    ),
                    decoration:
                        BoxDecoration(
                      color: leadOff
                          ? const Color(
                              0xFFFFF5E8,
                            )
                          : const Color(
                              0xFFECF9F1,
                            ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        19,
                      ),
                    ),
                    child:
                        Row(
                      children: [
                        Icon(
                          leadOff
                              ? Icons
                                  .warning_amber_rounded
                              : Icons
                                  .check_circle_rounded,
                          color: leadOff
                              ? Colors.orange
                              : Colors.green,
                          size:
                              28,
                        ),

                        const SizedBox(
                          width:
                              12,
                        ),

                        Expanded(
                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                leadOff
                                    ? 'Electrode Lead Off'
                                    : 'ECG Captured',
                                style:
                                    TextStyle(
                                  color: leadOff
                                      ? Colors.orange
                                      : Colors.green,
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize:
                                      16,
                                ),
                              ),

                              const SizedBox(
                                height:
                                    2,
                              ),

                              Text(
                                AppMode.isDemo
                                    ? 'Simulated electrodes are connected for demonstration.'
                                    : leadOff
                                        ? 'Check the AD8232 electrode connections.'
                                        : 'A waveform recording is available for review.',
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.blueGrey,
                                  fontSize:
                                      12,
                                ),
                              ),
                            ],
                          ),
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
                      16,
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
                            const Color(
                          0xFFE2E9F1,
                        ),
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
                                  .show_chart_rounded,
                              color:
                                  blue,
                            ),
                            SizedBox(
                              width:
                                  8,
                            ),
                            Text(
                              'ECG Waveform',
                              style:
                                  TextStyle(
                                color:
                                    navy,
                                fontSize:
                                    18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height:
                              8,
                        ),

                        Text(
                          recordingId ==
                                  null
                              ? 'No recording available'
                              : 'Recording $recordingId',
                          style:
                              const TextStyle(
                            color:
                                Colors.blueGrey,
                            fontSize:
                                11,
                          ),
                        ),

                        const SizedBox(
                          height:
                              15,
                        ),

                        Container(
                          width:
                              double.infinity,
                          height:
                              260,
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFF07130F,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),
                          ),
                          clipBehavior:
                              Clip.antiAlias,
                          child:
                              loadingWaveform
                                  ? const Center(
                                      child:
                                          CircularProgressIndicator(),
                                    )
                                  : samples.isEmpty
                                      ? const _NoEcgWaveform()
                                      : CustomPaint(
                                          painter:
                                              _EcgPainter(
                                            samples:
                                                samples,
                                          ),
                                          child:
                                              const SizedBox.expand(),
                                        ),
                        ),

                        const SizedBox(
                          height:
                              12,
                        ),

                        Text(
                          AppMode.isDemo
                              ? 'This waveform is generated locally for demonstration. No ESP32 or Firebase ECG recording is being used.'
                              : 'The waveform is displayed from the latest ECG recording captured by the Medicare device.',
                          style:
                              const TextStyle(
                            color:
                                Colors.blueGrey,
                            fontSize:
                                11,
                            height:
                                1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  const Text(
                    'Recording Details',
                    style:
                        TextStyle(
                      color:
                          navy,
                      fontSize:
                          18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _InfoCard(
                          icon:
                              Icons.speed_rounded,
                          title:
                              'Sample Rate',
                          value:
                              '$sampleRate Hz',
                        ),
                      ),

                      const SizedBox(
                        width:
                            10,
                      ),

                      Expanded(
                        child:
                            _InfoCard(
                          icon:
                              Icons.timeline_rounded,
                          title:
                              'Samples',
                          value:
                              '$sampleCount',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _InfoCard(
                          icon:
                              Icons.timer_outlined,
                          title:
                              'Duration',
                          value:
                              _durationText(),
                        ),
                      ),

                      const SizedBox(
                        width:
                            10,
                      ),

                      Expanded(
                        child:
                            _InfoCard(
                          icon:
                              Icons.analytics_outlined,
                          title:
                              'ADC Average',
                          value:
                              '$average',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets
                            .all(
                      16,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(
                        18,
                      ),
                    ),
                    child:
                        Row(
                      children: [
                        const Icon(
                          Icons
                              .schedule_rounded,
                          color:
                              blue,
                        ),

                        const SizedBox(
                          width:
                              10,
                        ),

                        Expanded(
                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Text(
                                'Recorded',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.blueGrey,
                                  fontSize:
                                      11,
                                ),
                              ),

                              const SizedBox(
                                height:
                                    2,
                              ),

                              Text(
                                _recordingTimeText(),
                                style:
                                    const TextStyle(
                                  color:
                                      navy,
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
                          0xFFFFF0F0,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          17,
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
                                .error_outline_rounded,
                            color:
                                Colors.red,
                          ),

                          const SizedBox(
                            width:
                                10,
                          ),

                          Expanded(
                            child:
                                Text(
                              error!,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.red,
                                fontSize:
                                    12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 20,
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
                        0xFFFFF8E8,
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
                              .info_outline_rounded,
                          color:
                              Color(
                            0xFFB97800,
                          ),
                        ),

                        const SizedBox(
                          width:
                              10,
                        ),

                        Expanded(
                          child:
                              Text(
                            AppMode.isDemo
                                ? 'This is a simulated ECG used only to demonstrate the MEDICARE app interface. It is not a recording from a real patient and must not be interpreted medically.'
                                : 'This ECG is produced by the Medicare prototype using an AD8232 single-channel sensor. It is intended for monitoring and engineering analysis and is not a clinical 12-lead ECG or a medical diagnosis.',
                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF795B24,
                              ),
                              fontSize:
                                  12,
                              height:
                                  1.45,
                            ),
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

// =============================================================
// NO ECG
// =============================================================

class _NoEcgWaveform
    extends StatelessWidget {
  const _NoEcgWaveform();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Center(
      child: Padding(
        padding:
            EdgeInsets.all(
          25,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons
                  .monitor_heart_outlined,
              color:
                  Colors.white54,
              size:
                  50,
            ),

            SizedBox(
              height:
                  12,
            ),

            Text(
              'No ECG waveform yet',
              style:
                  TextStyle(
                color:
                    Colors.white,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(
              height:
                  5,
            ),

            Text(
              'Complete an ECG measurement on the Medicare device.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.white54,
                fontSize:
                    11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// INFO CARD
// =============================================================

class _InfoCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
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
          const EdgeInsets
              .all(
        15,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius
                .circular(
          18,
        ),
        border:
            Border.all(
          color:
              const Color(
            0xFFE4EAF1,
          ),
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Icon(
            icon,
            color:
                const Color(
              0xFF0968D8,
            ),
            size:
                22,
          ),

          const SizedBox(
            height:
                9,
          ),

          Text(
            title,
            style:
                const TextStyle(
              color:
                  Colors.blueGrey,
              fontSize:
                  10,
            ),
          ),

          const SizedBox(
            height:
                3,
          ),

          FittedBox(
            child:
                Text(
              value,
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

// =============================================================
// ECG PAINTER
// =============================================================

class _EcgPainter
    extends CustomPainter {
  final List<double> samples;

  _EcgPainter({
    required this.samples,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (samples.length < 2) {
      return;
    }

    // ==========================================================
    // ECG GRID
    // ==========================================================

    final smallGridPaint =
        Paint()
          ..color =
              const Color(
            0xFF144331,
          )
          ..strokeWidth =
              0.5;

    final largeGridPaint =
        Paint()
          ..color =
              const Color(
            0xFF1C6847,
          )
          ..strokeWidth =
              0.8;

    const smallSpacing =
        10.0;

    const largeSpacing =
        50.0;

    for (
      double x = 0;
      x <= size.width;
      x += smallSpacing
    ) {
      final isLarge =
          (x % largeSpacing)
                  .abs() <
              0.1;

      canvas.drawLine(
        Offset(
          x,
          0,
        ),
        Offset(
          x,
          size.height,
        ),
        isLarge
            ? largeGridPaint
            : smallGridPaint,
      );
    }

    for (
      double y = 0;
      y <= size.height;
      y += smallSpacing
    ) {
      final isLarge =
          (y % largeSpacing)
                  .abs() <
              0.1;

      canvas.drawLine(
        Offset(
          0,
          y,
        ),
        Offset(
          size.width,
          y,
        ),
        isLarge
            ? largeGridPaint
            : smallGridPaint,
      );
    }

    // ==========================================================
    // SCALE ECG
    // ==========================================================

    final sorted =
        List<double>.from(
          samples,
        )..sort();

    final lowerIndex =
        math.max(
      0,
      (sorted.length *
              0.02)
          .floor(),
    );

    final upperIndex =
        math.min(
      sorted.length -
          1,
      (sorted.length *
              0.98)
          .floor(),
    );

    double minValue =
        sorted[
            lowerIndex];

    double maxValue =
        sorted[
            upperIndex];

    if ((maxValue -
                minValue)
            .abs() <
        1) {
      minValue -=
          1;

      maxValue +=
          1;
    }

    final range =
        maxValue -
            minValue;

    minValue -=
        range *
            0.15;

    maxValue +=
        range *
            0.15;

    // ==========================================================
    // ECG SIGNAL
    // ==========================================================

    final signalPaint =
        Paint()
          ..color =
              const Color(
            0xFF42FF8C,
          )
          ..strokeWidth =
              1.6
          ..strokeCap =
              StrokeCap.round
          ..strokeJoin =
              StrokeJoin.round
          ..style =
              PaintingStyle
                  .stroke;

    final path =
        Path();

    final count =
        samples.length;

    for (
      int i = 0;
      i < count;
      i++
    ) {
      final value =
          samples[i];

      final x =
          count <= 1
              ? 0.0
              : i /
                  (count -
                      1) *
                  size.width;

      final normalized =
          ((value -
                      minValue) /
                  (maxValue -
                      minValue))
              .clamp(
        0.0,
        1.0,
      );

      final y =
          size.height -
              normalized *
                  size.height;

      if (i == 0) {
        path.moveTo(
          x,
          y,
        );
      } else {
        path.lineTo(
          x,
          y,
        );
      }
    }

    canvas.drawPath(
      path,
      signalPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _EcgPainter
        oldDelegate,
  ) {
    return oldDelegate.samples !=
        samples;
  }
}