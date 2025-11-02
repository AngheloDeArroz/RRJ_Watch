import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/water_data_point.dart';

class WaterQualityChart extends StatelessWidget {
  const WaterQualityChart({super.key});

  Stream<List<WaterDataPoint>> _streamData() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('hourly-water-quality')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
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
          return Text('Error: ${snapshot.error}', style: const TextStyle(fontFamily: 'Lexend'));
        }

        final data = snapshot.data ?? [];
        final hasAnyData = data.isNotEmpty;

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
            if (!hasAnyData)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'No data recorded yet today.',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            _buildGraph(context, 'Temperature (°C)', data, (d) => d.temperature, Colors.red),
            const SizedBox(height: 24),
            _buildGraph(context, 'Turbidity (NTU)', data, (d) => d.turbidity, Colors.blue),
            const SizedBox(height: 24),
            _buildGraph(context, 'pH Level', data, (d) => d.ph, Colors.green),
          ],
        );
      },
    );
  }

  Widget _buildGraph(
    BuildContext context,
    String title,
    List<WaterDataPoint> data,
    double Function(WaterDataPoint) getY,
    Color color,
  ) {
    final dateFormat = DateFormat('h:mma');

    final rawSpots = <FlSpot>[];
    final timeLabels = <String>[];

    for (final d in data) {
      if (d.timestamp != null) {
        rawSpots.add(FlSpot(rawSpots.length.toDouble(), getY(d)));
        timeLabels.add(dateFormat.format(d.timestamp)); // Format DateTime
      }
    }

    final hasData = rawSpots.isNotEmpty;

    double minY = 0;
    double maxY = 10;
    if (hasData) {
      final ys = rawSpots.map((s) => s.y).toList();
      minY = ys.reduce((a, b) => a < b ? a : b);
      maxY = ys.reduce((a, b) => a > b ? a : b);
      if ((maxY - minY).abs() < 0.0001) {
        minY -= 1;
        maxY += 1;
      } else {
        final pad = (maxY - minY) * 0.05;
        minY -= pad;
        maxY += pad;
      }
    }

    final yRange = maxY - minY;
    final horizontalInterval = yRange > 0 ? yRange / 5 : 1.0;

    final numPoints = rawSpots.length;
    const pointWidth = 60.0;
    final enableScroll = numPoints > 6;
    final chartWidth = enableScroll
        ? numPoints * pointWidth
        : MediaQuery.of(context).size.width - 60;

    double minX = 0;
    double maxX = numPoints > 1 ? numPoints - 1 : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
          height: 220,
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    final yLabel = minY + (i * (yRange / 5));
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        yLabel.isFinite ? yLabel.toStringAsFixed(1) : '0.0',
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
                child: enableScroll
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: chartWidth,
                          child: _lineChart(
                            rawSpots,
                            minX,
                            maxX,
                            minY,
                            maxY,
                            color,
                            horizontalInterval,
                            timeLabels,
                          ),
                        ),
                      )
                    : _lineChart(
                        rawSpots,
                        minX,
                        maxX,
                        minY,
                        maxY,
                        color,
                        horizontalInterval,
                        timeLabels,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lineChart(
    List<FlSpot> spots,
    double minX,
    double maxX,
    double minY,
    double maxY,
    Color color,
    double horizontalInterval,
    List<String> timeLabels,
  ) {
    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: const FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= timeLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    timeLabels[index],
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
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: horizontalInterval,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade300, strokeWidth: 1),
          getDrawingVerticalLine: (value) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: Colors.black),
            bottom: BorderSide(color: Colors.black),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black87,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(6),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final label = timeLabels[spot.x.toInt()];
                return LineTooltipItem(
                  '$label\n${spot.y.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
