import 'dart:convert';

import 'package:http/http.dart' as http;

import 'openai_config.dart';

class AiService {
  // ============================================================
  // BASIC ANALYSIS
  // ============================================================
  //
  // Kept for compatibility with any older part of the app.
  //

  Future<String> analyze({
    int? heartRate,
    int? spo2,
    double? bodyTemperature,
    double? roomTemperature,
    double? humidity,
    double? sleepHours,
    String? mood,
    String? symptoms,
  }) async {
    return analyzeComprehensive(
      latestVitals: {
        'heartRate': heartRate,
        'spo2': spo2,
        'bodyTemperature': bodyTemperature,
        'roomTemperature': roomTemperature,
        'humidity': humidity,
      },
      history: const [],
      dailyCheckIns: [
        {
          'sleepHours': sleepHours,
          'mood': mood,
          'symptoms': symptoms,
        },
      ],
    );
  }

  // ============================================================
  // COMPREHENSIVE MEDICARE AI ANALYSIS
  // ============================================================

  Future<String> analyzeComprehensive({
    required Map<dynamic, dynamic>? latestVitals,
    required List<Map<String, dynamic>> history,
    required List<Map<String, dynamic>> dailyCheckIns,
  }) async {
    final latest = _normalizeMap(
      latestVitals,
    );

    final historyJson =
        _safeJsonEncode(
      history,
    );

    final dailyJson =
        _safeJsonEncode(
      dailyCheckIns,
    );

    final latestJson =
        _safeJsonEncode(
      latest,
    );

    final prompt = '''
You are the AI analysis component of a biomedical engineering patient-monitoring prototype called MEDICARE.

IMPORTANT ROLE:
You are a monitoring and decision-support assistant.
You are NOT a physician.
You must NOT diagnose diseases.
You must NOT claim that a future medical event is certain.

Your task is to combine:

1. The patient's latest sensor measurements.
2. Recent historical sensor measurements.
3. Recent Daily Check-In answers.
4. Trends across time.
5. Repeated symptoms.
6. Measurement validity and possible sensor-quality issues.

============================================================
LATEST SENSOR DATA
============================================================

$latestJson

============================================================
RECENT SENSOR HISTORY
============================================================

$historyJson

The records are normally ordered from newest to older.

============================================================
RECENT DAILY CHECK-INS
============================================================

$dailyJson

The Daily Check-In may include:

- mood
- sleep hours
- sleep quality
- fatigue
- dizziness
- shortness of breath
- chest discomfort
- headache
- nausea
- pain level
- appetite
- stress level
- free-text symptoms
- notes

============================================================
ANALYSIS RULES
============================================================

Analyze the information conservatively.

Do NOT infer a medical condition from one isolated measurement.

Look for longitudinal patterns such as:

- resting heart rate gradually increasing or decreasing
- SpO2 gradually decreasing
- repeated abnormal temperature
- repeated alerts
- worsening sleep duration or sleep quality
- repeated fatigue
- repeated dizziness
- repeated shortness of breath
- repeated chest discomfort
- increasing pain
- increasing stress
- changes in appetite
- subjective symptoms becoming worse while sensor measurements also worsen

Give more importance to a pattern that appears across multiple days than to one isolated reading.

If measurements are missing, invalid, or contradictory, explicitly say that the available evidence is limited.

If heartRateValid is false, do not treat the heart-rate number as reliable.

If spo2Valid is false, do not treat the SpO2 number as reliable.

If ecgLeadOff is true, explain that ECG information is not reliable because the electrodes were disconnected.

The AD8232 used by this prototype is a single-channel educational/monitoring ECG sensor. Do not interpret it as a diagnostic 12-lead ECG.

============================================================
EARLY DETECTION
============================================================

The "Early Risk Signals" section is NOT disease prediction.

It means:
"Is the available history moving toward a potentially concerning pattern that deserves closer monitoring or professional assessment?"

Classify the longitudinal risk pattern as exactly one of:

LOW
MODERATE
HIGH
INSUFFICIENT DATA

Use HIGH only when multiple meaningful concerning findings or symptoms are present.

Never say:
"You will develop..."
"You have..."
"You definitely..."
"This proves..."

Instead use wording such as:
"The recent pattern may warrant..."
"The available history shows..."
"If this trend continues..."
"This could justify professional assessment..."

If severe or concerning symptoms are reported, especially significant chest discomfort, major shortness of breath, fainting-type symptoms, or strongly abnormal vital signs, advise appropriate prompt medical evaluation.

Do not encourage the patient to delay urgent care while waiting for another Medicare measurement.

============================================================
OUTPUT FORMAT
============================================================

Respond using EXACTLY these headings:

Overall Status:
Current Measurements:
Trend Analysis:
Daily Check-In Analysis:
Early Risk Signals:
Why Medicare Flagged This:
Recommended Next Step:

Under "Early Risk Signals:" begin with:

Risk level: LOW

or

Risk level: MODERATE

or

Risk level: HIGH

or

Risk level: INSUFFICIENT DATA

Then explain the reasoning briefly.

Under "Why Medicare Flagged This:" list the most important pieces of evidence that contributed to the assessment.

Keep the response understandable to a patient while remaining technically responsible.

Do not diagnose disease.
''';

    return _sendPrompt(
      prompt,
    );
  }

  // ============================================================
  // EARLY-DETECTION-FOCUSED ANALYSIS
  // ============================================================

  Future<String> analyzeEarlyDetection({
    required List<Map<String, dynamic>> history,
    required List<Map<String, dynamic>> dailyCheckIns,
  }) async {
    final historyJson =
        _safeJsonEncode(
      history,
    );

    final dailyJson =
        _safeJsonEncode(
      dailyCheckIns,
    );

    final prompt = '''
You are the Early Detection module of MEDICARE, a biomedical engineering patient-monitoring prototype.

This is NOT a diagnostic system.

Analyze longitudinal patterns only.

============================================================
RECENT SENSOR HISTORY
============================================================

$historyJson

============================================================
RECENT DAILY CHECK-INS
============================================================

$dailyJson

============================================================
TASK
============================================================

Look for meaningful trends across time.

Examples include:

- rising resting heart rate across repeated valid measurements
- falling SpO2 across repeated valid measurements
- repeated abnormal body temperature
- repeated medical alerts
- worsening sleep
- worsening fatigue
- repeated dizziness
- repeated shortness of breath
- repeated chest discomfort
- increasing pain level
- worsening stress
- appetite changes
- combinations of objective measurements and reported symptoms

Do NOT diagnose disease.

Do NOT predict a specific future disease.

Do NOT say that a future event will certainly happen.

Instead estimate whether the patient's recent history shows a concerning direction that could justify closer monitoring or medical assessment.

============================================================
RISK LEVEL
============================================================

Choose exactly one:

LOW
MODERATE
HIGH
INSUFFICIENT DATA

HIGH should require multiple concerning findings, persistent worsening, or important symptoms.

============================================================
OUTPUT
============================================================

Respond using exactly:

Risk Level:
Pattern Detected:
Important Changes:
Possible Future Concern:
Recommended Action:
Data Limitations:

For "Possible Future Concern", describe only the type of risk pattern, not a diagnosis.

Examples:

- possible worsening oxygenation pattern
- possible increasing cardiovascular strain pattern
- persistent fever-like measurement trend
- worsening general health pattern
- no meaningful deterioration detected

Keep the wording conservative.
''';

    return _sendPrompt(
      prompt,
    );
  }

  // ============================================================
  // OPENAI REQUEST
  // ============================================================

  Future<String> _sendPrompt(
    String prompt,
  ) async {
    if (OpenAIConfig.apiKey.trim().isEmpty) {
      throw Exception(
        'OpenAI API key is missing.',
      );
    }

    final response = await http.post(
      Uri.parse(
        'https://api.openai.com/v1/responses',
      ),
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer ${OpenAIConfig.apiKey}',
      },
      body: jsonEncode({
        'model': 'gpt-5.6-luna',
        'input': prompt,
      }),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'OpenAI error ${response.statusCode}: ${response.body}',
      );
    }

    final decoded =
        jsonDecode(
      response.body,
    );

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid OpenAI response.',
      );
    }

    return _extractResponseText(
      decoded,
    );
  }

  // ============================================================
  // EXTRACT RESPONSES API TEXT
  // ============================================================

  String _extractResponseText(
    Map<String, dynamic> data,
  ) {
    final directOutputText =
        data['output_text'];

    if (directOutputText is String &&
        directOutputText.trim().isNotEmpty) {
      return directOutputText.trim();
    }

    final output =
        data['output'];

    if (output is! List) {
      throw Exception(
        'OpenAI returned no readable analysis.',
      );
    }

    final buffer =
        StringBuffer();

    for (final item in output) {
      if (item is! Map) {
        continue;
      }

      final content =
          item['content'];

      if (content is! List) {
        continue;
      }

      for (final part in content) {
        if (part is! Map) {
          continue;
        }

        final type =
            part['type']?.toString();

        final text =
            part['text'];

        if ((type == 'output_text' ||
                type == 'text' ||
                type == null) &&
            text is String &&
            text.trim().isNotEmpty) {
          if (buffer.isNotEmpty) {
            buffer.writeln();
          }

          buffer.write(
            text.trim(),
          );
        }
      }
    }

    final result =
        buffer.toString().trim();

    if (result.isEmpty) {
      throw Exception(
        'OpenAI returned no analysis.',
      );
    }

    return result;
  }

  // ============================================================
  // NORMALIZE FIREBASE MAP
  // ============================================================

  Map<String, dynamic> _normalizeMap(
    Map<dynamic, dynamic>? input,
  ) {
    if (input == null) {
      return {};
    }

    final output =
        <String, dynamic>{};

    for (final entry in input.entries) {
      output[
          entry.key.toString()] =
          _normalizeValue(
        entry.value,
      );
    }

    return output;
  }

  dynamic _normalizeValue(
    dynamic value,
  ) {
    if (value is Map) {
      final map =
          <String, dynamic>{};

      for (final entry in value.entries) {
        map[
            entry.key.toString()] =
            _normalizeValue(
          entry.value,
        );
      }

      return map;
    }

    if (value is List) {
      return value
          .map(
            _normalizeValue,
          )
          .toList();
    }

    return value;
  }

  // ============================================================
  // SAFE JSON
  // ============================================================

  String _safeJsonEncode(
    dynamic value,
  ) {
    try {
      return const JsonEncoder.withIndent(
        '  ',
      ).convert(
        value,
      );
    } catch (_) {
      return value.toString();
    }
  }
}