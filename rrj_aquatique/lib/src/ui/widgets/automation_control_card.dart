import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AutomationControlCard extends StatefulWidget {
  const AutomationControlCard({super.key});

  @override
  State<AutomationControlCard> createState() => _AutomationControlCardState();
}

class _AutomationControlCardState extends State<AutomationControlCard>
    with TickerProviderStateMixin {
  bool isOffline = false;
  int selectedTabIndex = 0;

  late final Connectivity _connectivity;
  late final Stream<List<ConnectivityResult>> _connectivityStream;

  final docRef = FirebaseFirestore.instance.collection('settings').doc('status');

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;

    _connectivityStream.listen((results) {
      final hasConnection = results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);
      setState(() {
        isOffline = !hasConnection;
      });
    });

    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    final results = await _connectivity.checkConnectivity();
    final hasConnection =
        results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);
    setState(() {
      isOffline = !hasConnection;
    });
  }

  DateTime _timeOfDayToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  Future<void> _saveSettings(Map<String, dynamic> updates) async {
    await docRef.set(updates, SetOptions(merge: true));
  }

  Future<void> _deleteFeedingData() async {
    await docRef.update({
      'feedingTime1': FieldValue.delete(),
      'feedingTime2': FieldValue.delete(),
      'feedingGrams1': FieldValue.delete(),
      'feedingGrams2': FieldValue.delete(),
    });
  }

  Future<void> _showFeedingDialog(int index) async {
    TimeOfDay selectedTime = TimeOfDay.now();
    int selectedGrams = 5;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Set Feeding Time and Amount",
            style: TextStyle(fontFamily: 'Lexend'),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      selectedTime.format(context),
                      style: const TextStyle(fontFamily: 'Lexend'),
                    ),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setStateDialog(() => selectedTime = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Feeding Amount: $selectedGrams g",
                    style: const TextStyle(fontFamily: 'Lexend'),
                  ),
                  Slider(
                    value: selectedGrams.toDouble(),
                    min: 5,
                    max: 100,
                    divisions: 19, // 5g increments
                    label: "$selectedGrams g",
                    onChanged: (value) {
                      setStateDialog(() =>
                          selectedGrams = (value / 5).round() * 5);
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(fontFamily: 'Lexend')),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveSettings({
                  'feedingEnabled': true,
                  if (index == 1)
                    'feedingTime1':
                        Timestamp.fromDate(_timeOfDayToDateTime(selectedTime)),
                  if (index == 2)
                    'feedingTime2':
                        Timestamp.fromDate(_timeOfDayToDateTime(selectedTime)),
                  if (index == 1) 'feedingGrams1': selectedGrams,
                  if (index == 2) 'feedingGrams2': selectedGrams,
                });
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(fontFamily: 'Lexend')),
            ),
          ],
        );
      },
    );
  }

  void _resetTime(int index) {
    docRef.update({
      if (index == 1) 'feedingTime1': FieldValue.delete(),
      if (index == 1) 'feedingGrams1': FieldValue.delete(),
      if (index == 2) 'feedingTime2': FieldValue.delete(),
      if (index == 2) 'feedingGrams2': FieldValue.delete(),
    });
  }

  Widget _buildFeedingTimeTile(
      String label, TimeOfDay? time, int? grams, int index) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontFamily: 'Lexend')),
      subtitle: Text(
        (time != null && grams != null)
            ? "${time.format(context)} / ${grams}g"
            : "Not set",
        style: const TextStyle(fontFamily: 'Lexend'),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: isOffline ? null : () => _showFeedingDialog(index),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: isOffline ? null : () => _resetTime(index),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab({
    required String label,
    required int index,
    required bool isActive,
    required bool isFeatureActive,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? Colors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(32),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Lexend',
                  color: isActive ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isFeatureActive)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    '(Active)',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 12,
                      color: isActive ? Colors.white70 : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> data) {
    final bool isFeedingEnabled = data['feedingEnabled'] ?? false;
    final bool isPhBalancerEnabled = data['phBalancerEnabled'] ?? false;

    final feedingTime1 = data['feedingTime1'] != null
        ? TimeOfDay.fromDateTime((data['feedingTime1'] as Timestamp).toDate())
        : null;
    final feedingTime2 = data['feedingTime2'] != null
        ? TimeOfDay.fromDateTime((data['feedingTime2'] as Timestamp).toDate())
        : null;

    final feedingGrams1 = data['feedingGrams1'];
    final feedingGrams2 = data['feedingGrams2'];

    if (selectedTabIndex == 0) {
      return Column(
        key: const ValueKey('feeding'),
        children: [
          SwitchListTile(
            title: const Text("Enable Feeding",
                style: TextStyle(fontFamily: 'Lexend')),
            subtitle: const Text("Turn on automated feeding schedules.",
                style: TextStyle(fontFamily: 'Lexend')),
            value: isFeedingEnabled,
            activeColor: Colors.teal,
            onChanged: isOffline
                ? null
                : (value) async {
                    if (!value) await _deleteFeedingData();
                    await _saveSettings({'feedingEnabled': value});
                  },
          ),
          if (isFeedingEnabled)
            ...[
              _buildFeedingTimeTile(
                  "Schedule 1", feedingTime1, feedingGrams1, 1),
              _buildFeedingTimeTile(
                  "Schedule 2", feedingTime2, feedingGrams2, 2),
            ],
        ],
      );
    } else {
      return Column(
        key: const ValueKey('ph'),
        children: [
          SwitchListTile(
            title: const Text("Enable pH Balancer",
                style: TextStyle(fontFamily: 'Lexend')),
            subtitle: const Text("Automatically maintain optimal pH levels.",
                style: TextStyle(fontFamily: 'Lexend')),
            value: isPhBalancerEnabled,
            activeColor: Colors.teal,
            onChanged: isOffline
                ? null
                : (value) => _saveSettings({'phBalancerEnabled': value}),
          ),
          if (isPhBalancerEnabled)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Target pH Range: 6.8 - 7.2",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lexend')),
                  SizedBox(height: 4),
                  Text(
                    "The system will automatically dose to keep the pH within this range.",
                    style:
                        TextStyle(color: Colors.grey, fontFamily: 'Lexend'),
                  ),
                ],
              ),
            ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Automation Controls",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontFamily: 'Lexend'),
                ),
                if (isOffline)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "You’re offline. Controls are disabled.",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontFamily: 'Lexend',
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: Colors.teal.shade50,
                  ),
                  child: Row(
                    children: [
                      _buildSegmentTab(
                        label: "Feeding",
                        index: 0,
                        isActive: selectedTabIndex == 0,
                        isFeatureActive: data['feedingEnabled'] ?? false,
                      ),
                      _buildSegmentTab(
                        label: "pH Balancer",
                        index: 1,
                        isActive: selectedTabIndex == 1,
                        isFeatureActive: data['phBalancerEnabled'] ?? false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildTabContent(data),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
