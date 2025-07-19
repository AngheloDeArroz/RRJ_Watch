import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/water_data_point.dart';

class WaterQualityChart extends StatelessWidget {
  const WaterQualityChart({super.key});

  Stream<List<WaterDataPoint>> _streamData() {
    return FirebaseFirestore.instance
        .collection('hourly-water-quality')
        .orderBy('timestamp', descending: true)
        .limit(24)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WaterDataPoint.fromMap(doc.data()))
            .toList()
            .reversed
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WaterDataPoint>>(
      stream: _streamData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: const TextStyle(fontFamily: 'Lexend'),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text(
            'No data available.',
            style: TextStyle(fontFamily: 'Lexend'),
          );
        }

        final data = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Water Trends',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            _buildGraph('Temperature (°C)', data, (d) => d.temperature, Colors.red),
            const SizedBox(height: 24),
            _buildGraph('Turbidity (NTU)', data, (d) => d.turbidity, Colors.blue),
            const SizedBox(height: 24),
            _buildGraph('pH Level', data, (d) => d.ph, Colors.green),
          ],
        );
      },
    );
  }

  Widget _buildGraph(
    String title,
    List<WaterDataPoint> data,
    double Function(WaterDataPoint) getY,
    Color color,
  ) {
    final spots = data.map((d) => FlSpot(d.hour.toDouble(), getY(d))).toList();
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final chartWidth = data.length * 60.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: maxY > 100 ? 260 : 220,
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    final yLabel = minY + (i * ((maxY - minY) / 5));
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        yLabel.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                          fontFamily: 'Lexend',
                        ),
                      ),
                    );
                  }).reversed.toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Opacity(opacity: value, child: child);
                      },
                      child: LineChart(
                        LineChartData(
                          minX: data.first.hour.toDouble(),
                          maxX: data.last.hour.toDouble(),
                          minY: minY - 1,
                          maxY: maxY + 0.5,
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              gradient: LinearGradient(
                                colors: [color.withOpacity(0.9), color.withOpacity(0.2)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              barWidth: 4,
                              isStrokeCapRound: true,
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [color.withOpacity(0.2), Colors.transparent],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                                  radius: 3,
                                  color: color,
                                  strokeWidth: 1.5,
                                  strokeColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      _formatHour(value.toInt()),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black54,
                                        fontFamily: 'Lexend',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: (maxY - minY) / 5,
                            verticalInterval: 1,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            ),
                            getDrawingVerticalLine: (value) => FlLine(
                              color: Colors.grey.shade200,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: const Border(
                              left: BorderSide(color: Colors.black),
                              bottom: BorderSide(color: Colors.black),
                            ),
                          ),
                          clipData: FlClipData.none(),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBgColor: Colors.black87,
                              tooltipRoundedRadius: 8,
                              tooltipMargin: 12,
                              fitInsideVertically: true,
                              fitInsideHorizontally: true,
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    '${spot.y.toStringAsFixed(2)}',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Lexend',
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatHour(int hour) {
    final suffix = hour < 12 ? 'AM' : 'PM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12 $suffix';
  }
}
