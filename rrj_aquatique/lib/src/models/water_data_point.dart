import 'package:cloud_firestore/cloud_firestore.dart';

class WaterDataPoint {
  final double temperature;
  final double turbidity;
  final double ph;
  final DateTime timestamp;

  WaterDataPoint({
    required this.temperature,
    required this.turbidity,
    required this.ph,
    required this.timestamp,
  });

  int get hour => timestamp.hour;

  factory WaterDataPoint.fromMap(Map<String, dynamic> map) {
    return WaterDataPoint(
      temperature: (map['temperature'] ?? 0).toDouble(),
      turbidity: (map['turbidity'] ?? 0).toDouble(),
      ph: (map['ph'] ?? 0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
