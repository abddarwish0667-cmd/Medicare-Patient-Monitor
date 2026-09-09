import 'package:flutter/material.dart';

import '../services/database_service.dart';

class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  State<DailyCheckInScreen> createState() =>
      _DailyCheckInScreenState();
}

class _DailyCheckInScreenState
    extends State<DailyCheckInScreen> {
  final DatabaseService database =
      DatabaseService();

  final TextEditingController symptomsController =
      TextEditingController();

  final TextEditingController notesController =
      TextEditingController();

  String mood = 'Good';
  String sleepQuality = 'Good';
  String appetite = 'Normal';

  double sleepHours = 7;

  int stressLevel = 2;
  int painLevel = 0;

  bool fatigue = false;
  bool dizziness = false;
  bool shortnessOfBreath = false;
  bool chestDiscomfort = false;
  bool headache = false;
  bool nausea = false;

  bool saving = false;

  final List<String> moods = const [
    'Excellent',
    'Good',
    'Okay',
    'Tired',
    'Unwell',
  ];

  final List<String> sleepQualities = const [
    'Excellent',
    'Good',
    'Fair',
    'Poor',
  ];

  final List<String> appetites = const [
    'Normal',
    'Low',
    'High',
  ];

  @override
  void dispose() {
    symptomsController.dispose();
    notesController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    if (saving) {
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await database.saveDailyCheckIn(
        mood: mood,
        sleepHours: sleepHours,
        sleepQuality: sleepQuality,
        stressLevel: stressLevel,
        painLevel: painLevel,
        appetite: appetite,
        fatigue: fatigue,
        dizziness: dizziness,
        shortnessOfBreath: shortnessOfBreath,
        chestDiscomfort: chestDiscomfort,
        headache: headache,
        nausea: nausea,
        symptoms: symptomsController.text.trim(),
        notes: notesController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save daily check-in.\n$e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 12,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _symptomTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Check-In',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text(
            'How are you feeling today?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Your answers are saved with your health history and can be used by Medicare AI for trend analysis.',
            style: TextStyle(
              color: Colors.blueGrey,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 22),

          _sectionTitle('Overall feeling'),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: moods.map((item) {
              return ChoiceChip(
                label: Text(item),
                selected: mood == item,
                onSelected: (_) {
                  setState(() {
                    mood = item;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          _sectionTitle('Sleep'),

          Text(
            '${sleepHours.toStringAsFixed(1)} hours',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          Slider(
            value: sleepHours,
            min: 0,
            max: 16,
            divisions: 32,
            label:
                '${sleepHours.toStringAsFixed(1)} h',
            onChanged: (value) {
              setState(() {
                sleepHours = value;
              });
            },
          ),

          const Text(
            'Sleep quality',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sleepQualities.map((item) {
              return ChoiceChip(
                label: Text(item),
                selected: sleepQuality == item,
                onSelected: (_) {
                  setState(() {
                    sleepQuality = item;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          _sectionTitle('Pain / discomfort'),

          Text(
            painLevel == 0
                ? 'No pain'
                : 'Pain level: $painLevel / 10',
          ),

          Slider(
            value: painLevel.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: '$painLevel',
            onChanged: (value) {
              setState(() {
                painLevel = value.round();
              });
            },
          ),

          const SizedBox(height: 18),

          _sectionTitle('Stress'),

          Text(
            'Stress level: $stressLevel / 10',
          ),

          Slider(
            value: stressLevel.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: '$stressLevel',
            onChanged: (value) {
              setState(() {
                stressLevel = value.round();
              });
            },
          ),

          const SizedBox(height: 18),

          _sectionTitle('Symptoms'),

          _symptomTile(
            title: 'Fatigue',
            icon: Icons.battery_2_bar_rounded,
            value: fatigue,
            onChanged: (value) {
              setState(() {
                fatigue = value;
              });
            },
          ),

          _symptomTile(
            title: 'Dizziness',
            icon: Icons.sync_problem_rounded,
            value: dizziness,
            onChanged: (value) {
              setState(() {
                dizziness = value;
              });
            },
          ),

          _symptomTile(
            title: 'Shortness of breath',
            icon: Icons.air_rounded,
            value: shortnessOfBreath,
            onChanged: (value) {
              setState(() {
                shortnessOfBreath = value;
              });
            },
          ),

          _symptomTile(
            title: 'Chest discomfort',
            icon: Icons.monitor_heart_outlined,
            value: chestDiscomfort,
            onChanged: (value) {
              setState(() {
                chestDiscomfort = value;
              });
            },
          ),

          _symptomTile(
            title: 'Headache',
            icon: Icons.psychology_outlined,
            value: headache,
            onChanged: (value) {
              setState(() {
                headache = value;
              });
            },
          ),

          _symptomTile(
            title: 'Nausea',
            icon: Icons.sick_outlined,
            value: nausea,
            onChanged: (value) {
              setState(() {
                nausea = value;
              });
            },
          ),

          const SizedBox(height: 18),

          _sectionTitle('Appetite'),

          Wrap(
            spacing: 8,
            children: appetites.map((item) {
              return ChoiceChip(
                label: Text(item),
                selected: appetite == item,
                onSelected: (_) {
                  setState(() {
                    appetite = item;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          TextField(
            controller: symptomsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Other symptoms',
              hintText:
                  'Describe anything else you noticed...',
              prefixIcon: Icon(
                Icons.medical_information_outlined,
              ),
            ),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Additional notes',
              hintText:
                  'Anything else Medicare should know today?',
              prefixIcon: Icon(
                Icons.notes_rounded,
              ),
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: saving
                  ? null
                  : _save,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.check_circle_outline,
                    ),
              label: Text(
                saving
                    ? 'SAVING...'
                    : 'COMPLETE CHECK-IN',
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}