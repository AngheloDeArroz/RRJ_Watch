import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../models/history_log.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<HistoryLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _fetchLogs();
  }

  Future<List<HistoryLog>> _fetchLogs() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('water-history')
        .orderBy('timestamp', descending: false)
        .limit(7)
        .get();

    final logs = snapshot.docs.map((doc) {
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
            }).toList() ?? [],
        phBalancerTriggered: data['isAutoPhEnabledToday'] ?? false,
        foodStart: data['foodLevelStartOfDay'] ?? 0,
        foodEnd: data['foodLevelEndOfDay'] ?? 0,
        phStart: data['phSolutionLevelStartOfDay'] ?? 0,
        phEnd: data['phSolutionLevelEndOfDay'] ?? 0,
      );
    }).toList();

    return logs.reversed.toList();
  }

  Future<void> _downloadPdf(List<HistoryLog> logs) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'Aquarium History Logs',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 12),
          ...logs.map((log) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Date: ${log.date}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Temp: ${log.temperature}°C'),
                  pw.Text('pH: ${log.ph}'),
                  pw.Text('Turbidity: ${log.turbidity} NTU'),
                  pw.Text('Food Level: ${log.foodEnd}% (↓ ${log.foodStart - log.foodEnd}%)'),
                  pw.Text('Feeding Times: ${log.feedingSchedules.join(', ')}'),
                  pw.Text('pH Solution Level: ${log.phEnd}% (↓ ${log.phStart - log.phEnd}%)'),
                  pw.Text('pH Balancer: ${log.phBalancerTriggered ? "Triggered" : "Not Triggered"}'),
                  pw.Divider(),
                ],
              ))
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<HistoryLog>>(
          future: _logsFuture,
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _downloadPdf(logs),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Download History PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final foodUsed = (log.foodStart - log.foodEnd).clamp(0, 100);
                      final phUsed = (log.phStart - log.phEnd).clamp(0, 100);
                      final bool phBalancerTriggered = log.phEnd < log.phStart;

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
                              Text(log.date, style: const TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Entypo.thermometer, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Temp: ${log.temperature}°C', style: const TextStyle(fontFamily: 'Lexend')),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(MaterialCommunityIcons.flask_outline, size: 16),
                                  const SizedBox(width: 6),
                                  Text('pH: ${log.ph}', style: const TextStyle(fontFamily: 'Lexend')),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(MaterialCommunityIcons.water, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Turbidity: ${log.turbidity} NTU', style: const TextStyle(fontFamily: 'Lexend')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('Food Level: ${log.foodEnd}% (↓ $foodUsed%)', style: const TextStyle(fontFamily: 'Lexend')),
                              if (log.feedingSchedules.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Feeding Times: ${log.feedingSchedules.join(', ')}',
                                    style: const TextStyle(fontFamily: 'Lexend', fontSize: 13, color: Colors.black87),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              _buildUsageBar(start: log.foodStart, end: log.foodEnd, color: Colors.orange),
                              Text('pH Solution Level: ${log.phEnd}% (↓ $phUsed%)', style: const TextStyle(fontFamily: 'Lexend')),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'pH Balancer: ${phBalancerTriggered ? "Triggered" : "Not Triggered"}',
                                  style: TextStyle(fontFamily: 'Lexend', fontSize: 13, color: phBalancerTriggered ? Colors.red : Colors.black),
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildUsageBar(start: log.phStart, end: log.phEnd, color: Colors.blueAccent),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUsageBar({required int start, required int end, required Color color}) {
    final startFraction = (start / 100).clamp(0.0, 1.0);
    final endFraction = (end / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                child: Container(decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8))),
              ),
              FractionallySizedBox(
                widthFactor: endFraction,
                child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Start: $start%', style: const TextStyle(fontFamily: 'Lexend', fontSize: 12)),
            Text('End: $end%', style: const TextStyle(fontFamily: 'Lexend', fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
