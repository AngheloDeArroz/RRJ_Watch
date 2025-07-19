import 'package:flutter/material.dart';
import '../widgets/hourly_water_quality_chart.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea( // ✅ prevents overlap with status bar
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // ✅ no top padding
        child: const WaterQualityChart(),
      ),
    );
  }
}
