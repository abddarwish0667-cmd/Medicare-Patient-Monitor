import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/vital_record.dart';
import '../services/app_mode.dart';
import '../services/database_service.dart';
import '../services/demo_data_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService database = DatabaseService();

  DatabaseReference? historyRef;

  bool loading = true;
  String? error;

  bool get isDemo => AppMode.isDemo;

  @override
  void initState() {
    super.initState();

    if (isDemo) {
      loading = false;
    } else {
      _loadHistoryReference();
    }
  }

  Future<void> _loadHistoryReference() async {
    if (isDemo) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = null;
      });

      return;
    }

    try {
      final ref = await database.getHistoryRef();

      if (!mounted) return;

      setState(() {
        historyRef = ref;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  String timeText(int? timestamp) {
    if (timestamp == null || timestamp <= 0) {
      return 'Unknown time';
    }

    try {
      // Firebase firmware timestamps are stored in seconds.
      // DemoDataService timestamps are milliseconds.
      final milliseconds =
          timestamp > 100000000000 ? timestamp : timestamp * 1000;

      final date = DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
      ).toLocal();

      return DateFormat(
        'dd MMM yyyy • HH:mm',
      ).format(date);
    } catch (_) {
      return 'Unknown time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text(
          'Checkup History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isDemo)
            Container(
              margin: const EdgeInsets.only(
                right: 14,
                top: 12,
                bottom: 12,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'DEMO',
                  style: TextStyle(
                    color: Color(0xFF673AB7),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isDemo) {
      return _buildDemoHistory();
    }

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null || historyRef == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.devices_other_outlined,
                size: 70,
                color: Colors.orange,
              ),
              const SizedBox(height: 18),
              const Text(
                'Unable to load device history',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                error ??
                    'No Medicare device is registered with this account.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadHistoryReference,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'TRY AGAIN',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: historyRef!.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 72,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Unable to load history',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final raw = snapshot.data!.snapshot.value;

        if (raw == null || raw is! Map) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 75,
                    color: Colors.blueGrey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'No checkups yet',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your Medicare measurements will appear here after a checkup.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final historyMap =
            Map<dynamic, dynamic>.from(raw);

        final records = <VitalRecord>[];

        for (final value in historyMap.values) {
          if (value is Map) {
            try {
              records.add(
                VitalRecord.fromMap(
                  Map<dynamic, dynamic>.from(value),
                ),
              );
            } catch (_) {
              // Ignore malformed entries.
            }
          }
        }

        if (records.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 75,
                    color: Colors.blueGrey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'No valid checkups found',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        records.sort((a, b) {
          final aTime = a.timestamp ?? 0;
          final bTime = b.timestamp ?? 0;

          return bTime.compareTo(aTime);
        });

        return _buildRecordList(
          records,
          demo: false,
        );
      },
    );
  }

  // ============================================================
  // DEMO HISTORY
  // ============================================================

  Widget _buildDemoHistory() {
    final records = <VitalRecord>[];

    for (final item in DemoDataService.history) {
      try {
        records.add(
          VitalRecord.fromMap(
            Map<dynamic, dynamic>.from(item),
          ),
        );
      } catch (_) {
        // Ignore malformed demo entries.
      }
    }

    records.sort((a, b) {
      final aTime = a.timestamp ?? 0;
      final bTime = b.timestamp ?? 0;

      return bTime.compareTo(aTime);
    });

    if (records.isEmpty) {
      return const Center(
        child: Text(
          'No demonstration history available.',
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
            18,
            16,
            18,
            0,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE7F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD1C4E9),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.science_outlined,
                color: Color(0xFF673AB7),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demonstration Mode\nThese are simulated patient measurements, not real medical data.',
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
        Expanded(
          child: _buildRecordList(
            records,
            demo: true,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RECORD LIST
  // ============================================================

  Widget _buildRecordList(
    List<VitalRecord> records, {
    required bool demo,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        if (demo) {
          await Future<void>.delayed(
            const Duration(milliseconds: 400),
          );

          if (mounted) {
            setState(() {});
          }

          return;
        }

        await _loadHistoryReference();
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          30,
        ),
        itemCount: records.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          return _buildRecordCard(
            records[index],
          );
        },
      ),
    );
  }

  // ============================================================
  // RECORD CARD
  // ============================================================

  Widget _buildRecordCard(
    VitalRecord record,
  ) {
    final heartRateText =
        record.heartRateValid &&
                record.heartRate != null
            ? '${record.heartRate}'
            : '--';

    final spo2Text =
        record.spo2Valid && record.spo2 != null
            ? '${record.spo2}'
            : '--';

    final temperatureText =
        record.bodyTemperature != null
            ? record.bodyTemperature!.toStringAsFixed(1)
            : '--';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: record.alert
              ? Colors.red.shade200
              : Colors.blueGrey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: record.alert
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  record.alert
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: record.alert
                      ? Colors.red
                      : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeText(record.timestamp),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      record.alert
                          ? 'Alert detected'
                          : 'Checkup completed',
                      style: TextStyle(
                        color: record.alert
                            ? Colors.red
                            : Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 28),

          Row(
            children: [
              Expanded(
                child: _VitalValue(
                  icon: Icons.favorite,
                  title: 'Heart Rate',
                  value: heartRateText,
                  unit: 'bpm',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _VitalValue(
                  icon: Icons.water_drop,
                  title: 'SpO₂',
                  value: spo2Text,
                  unit: '%',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(
                Icons.thermostat,
                size: 20,
                color: Color(0xFF0759C7),
              ),
              const SizedBox(width: 8),
              const Text(
                'Body Temperature:',
                style: TextStyle(
                  color: Colors.blueGrey,
                ),
              ),
              const Spacer(),
              Text(
                '$temperatureText °C',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                Icons.monitor_heart,
                size: 20,
                color: record.ecgLeadOff
                    ? Colors.orange
                    : Colors.green,
              ),
              const SizedBox(width: 8),
              const Text(
                'ECG:',
                style: TextStyle(
                  color: Colors.blueGrey,
                ),
              ),
              const Spacer(),
              Text(
                record.ecgLeadOff
                    ? 'Lead Off'
                    : 'Captured',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: record.ecgLeadOff
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
            ],
          ),

          if (record.batteryPercent != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.battery_full,
                  size: 20,
                  color: Color(0xFF0759C7),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Device Battery:',
                  style: TextStyle(
                    color: Colors.blueGrey,
                  ),
                ),
                const Spacer(),
                Text(
                  '${record.batteryPercent}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VitalValue extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;

  const _VitalValue({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: const Color(0xFF0759C7),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF092D6B),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 2,
                ),
                child: Text(
                  unit,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}