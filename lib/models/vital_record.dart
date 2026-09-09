class VitalRecord {
  final int? heartRate;
  final int? spo2;
  final double? bodyTemperature;
  final double? roomTemperature;
  final double? humidity;
  final int? batteryPercent;

  final bool heartRateValid;
  final bool spo2Valid;
  final bool ecgLeadOff;
  final bool alert;

  final int? timestamp;

  VitalRecord({
    this.heartRate,
    this.spo2,
    this.bodyTemperature,
    this.roomTemperature,
    this.humidity,
    this.batteryPercent,
    this.heartRateValid = false,
    this.spo2Valid = false,
    this.ecgLeadOff = true,
    this.alert = false,
    this.timestamp,
  });

  factory VitalRecord.fromMap(Map<dynamic, dynamic> data) {
    return VitalRecord(
      heartRate: _toInt(data['heartRate']),
      spo2: _toInt(data['spo2']),
      bodyTemperature: _toDouble(data['bodyTemperature']),
      roomTemperature: _toDouble(data['roomTemperature']),
      humidity: _toDouble(data['humidity']),
      batteryPercent: _toInt(data['batteryPercent']),
      heartRateValid: _toBool(data['heartRateValid']),
      spo2Valid: _toBool(data['spo2Valid']),
      ecgLeadOff: _toBool(data['ecgLeadOff']),
      alert: _toBool(data['alert']),
      timestamp: _toInt(data['timestamp']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;

    if (value == 1 || value == '1') {
      return true;
    }

    return value.toString().toLowerCase() == 'true';
  }
}
