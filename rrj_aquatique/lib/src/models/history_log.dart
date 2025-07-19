import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryLog {
  final String date;
  final String temperature;
  final String turbidity;
  final String ph;
  final List<String> feedingSchedules;
  final bool phBalancerTriggered;
  final int foodStart;
  final int foodEnd;
  final int phStart;
  final int phEnd;

  HistoryLog({
    required this.date,
    required this.temperature,
    required this.turbidity,
    required this.ph,
    required this.feedingSchedules,
    required this.phBalancerTriggered,
    required this.foodStart,
    required this.foodEnd,
    required this.phStart,
    required this.phEnd,
  });

  factory HistoryLog.fromFirestore(Map<String, dynamic> data) {
    final timestamp = data['timestamp'];
    final dateString = timestamp is Timestamp
        ? timestamp.toDate().toIso8601String()
        : 'Unknown';

    return HistoryLog(
      date: dateString,
      temperature: data['temp']?.toString() ?? '-',
      turbidity: data['turbidity']?.toString() ?? '-',
      ph: data['ph']?.toString() ?? '-',
      feedingSchedules:
          List<String>.from(data['feedingSchedules'] ?? []),
      phBalancerTriggered: data['isAutoPhEnabledToday'] ?? false,
      foodStart: data['foodLevelStartOfDay'] ?? 0,
      foodEnd: data['foodLevelEndOfDay'] ?? 0,
      phStart: data['phSolutionLevelStartOfDay'] ?? 0,
      phEnd: data['phSolutionLevelEndOfDay'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'temperature': temperature,
      'turbidity': turbidity,
      'ph': ph,
      'feedingSchedules': feedingSchedules,
      'phBalancerTriggered': phBalancerTriggered,
      'foodLevelStartOfDay': foodStart,
      'foodLevelEndOfDay': foodEnd,
      'phSolutionLevelStartOfDay': phStart,
      'phSolutionLevelEndOfDay': phEnd,
    };
  }
}
