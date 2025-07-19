import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../../models/history_log.dart';
import '../../services/ai_service.dart';
import 'ai_insight_dialog.dart';

class HistoryInsightsDialog {
  static Future<void> show(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => const _HistoryInsightsModal(),
    );
  }
}

class _HistoryInsightsModal extends StatefulWidget {
  const _HistoryInsightsModal({super.key});

  @override
  State<_HistoryInsightsModal> createState() => _HistoryInsightsModalState();
}

class _HistoryInsightsModalState extends State<_HistoryInsightsModal> {
  bool _isGenerating = false;

  Future<List<HistoryLog>> _fetchLogs() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('water-history')
        .orderBy('timestamp', descending: true)
        .limit(7)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final timestamp = data['timestamp'] as Timestamp?;
      final formattedDate = timestamp != null
          ? DateFormat('MMM d, yyyy - hh:mm a').format(timestamp.toDate())
          : 'Unknown';

      return HistoryLog(
        date: formattedDate,
        temperature: data['temp']?.toString() ?? '-',
        turbidity: data['turbidity']?.toString() ?? '-',
        ph: data['ph']?.toString() ?? '-',
        feedingSchedules: (data['feedingSchedules'] as List<dynamic>?)?.map((e) {
              try {
                final date = (e as Timestamp).toDate();
                return DateFormat('hh:mm a').format(date);
              } catch (_) {
                return e.toString();
              }
            }).toList() ??
            [],
        phBalancerTriggered: data['isAutoPhEnabledToday'] ?? false,
        foodStart: data['foodLevelStartOfDay'] ?? 0,
        foodEnd: data['foodLevelEndOfDay'] ?? 0,
        phStart: data['phSolutionLevelStartOfDay'] ?? 0,
        phEnd: data['phSolutionLevelEndOfDay'] ?? 0,
      );
    }).toList();
  }

  void _generateAIInsights(List<HistoryLog> logs) async {
    setState(() => _isGenerating = true);
    try {
      final jsonData = logs.map((e) => e.toJson()).toList();
      final response = await AiService.generateInsightsFromLogs(jsonData);

      if (!mounted) return;
      AiInsightDialog.show(context, response);
    } catch (e) {
      if (!mounted) return;
      AiInsightDialog.show(context, 'Failed to load AI insights.');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: double.maxFinite,
        height: 550,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<List<HistoryLog>>(
            future: _fetchLogs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(fontFamily: 'Lexend'),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No history found.',
                    style: TextStyle(fontFamily: 'Lexend'),
                  ),
                );
              }

              final logs = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System History (Last 7 Days)',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final foodUsed = (log.foodStart - log.foodEnd).clamp(0, 100);
                        final phUsed = (log.phStart - log.phEnd).clamp(0, 100);

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.date,
                                  style: const TextStyle(
                                    fontFamily: 'Lexend',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Entypo.thermometer, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Temp: ${log.temperature}°C',
                                          style: const TextStyle(fontFamily: 'Lexend'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(MaterialCommunityIcons.flask_outline, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'pH: ${log.ph}',
                                          style: const TextStyle(fontFamily: 'Lexend'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(MaterialCommunityIcons.water, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Turbidity: ${log.turbidity} NTU',
                                          style: const TextStyle(fontFamily: 'Lexend'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Text(
                                  'Food Level: ${log.foodEnd}% (↓ $foodUsed%)',
                                  style: const TextStyle(
                                    fontFamily: 'Lexend',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (log.feedingSchedules.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Feeding Times: ${log.feedingSchedules.join(', ')}',
                                      style: const TextStyle(
                                        fontFamily: 'Lexend',
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                _buildUsageBar(
                                  title: '',
                                  start: log.foodStart,
                                  end: log.foodEnd,
                                  color: Colors.orange,
                                ),

                                Text(
                                  'pH Solution Level: ${log.phEnd}% (↓ $phUsed%)',
                                  style: const TextStyle(
                                    fontFamily: 'Lexend',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'pH Balancer: ${log.phBalancerTriggered ? "Enabled" : "Disabled"}',
                                    style: const TextStyle(
                                      fontFamily: 'Lexend',
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildUsageBar(
                                  title: '',
                                  start: log.phStart,
                                  end: log.phEnd,
                                  color: Colors.blueAccent,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_isGenerating)
                        const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _generateAIInsights(logs),
                          icon: const Icon(Icons.insights),
                          label: const Text(
                            'Generate AI Insights',
                            style: TextStyle(fontFamily: 'Lexend'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontFamily: 'Lexend'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUsageBar({
    required String title,
    required int start,
    required int end,
    required Color color,
  }) {
    final startFraction = (start / 100).clamp(0.0, 1.0);
    final endFraction = (end / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(
            '$title Level: $end%',
            style: const TextStyle(
              fontFamily: 'Lexend',
              fontWeight: FontWeight.w500,
            ),
          ),
        Container(
          height: 16,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: startFraction,
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: endFraction,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Start: $start%',
              style: const TextStyle(fontFamily: 'Lexend', fontSize: 12),
            ),
            Text(
              'End: $end%',
              style: const TextStyle(fontFamily: 'Lexend', fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
