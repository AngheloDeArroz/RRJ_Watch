import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AutomationControlCard extends StatefulWidget {
  const AutomationControlCard({super.key});

  @override
  State<AutomationControlCard> createState() => _AutomationControlCardState();
}

class _AutomationControlCardState extends State<AutomationControlCard>
    with TickerProviderStateMixin {
  bool isFeedingEnabled = false;
  bool isPhBalancerEnabled = false;
  TimeOfDay? feedingTime1;
  TimeOfDay? feedingTime2;

  final docRef = FirebaseFirestore.instance
      .collection('settings')
      .doc('status');
  int selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await docRef.get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        isFeedingEnabled = data['feedingEnabled'] ?? false;
        isPhBalancerEnabled = data['phBalancerEnabled'] ?? false;
        if (data['feedingTime1'] != null && data['feedingTime1'] is Timestamp) {
          feedingTime1 = TimeOfDay.fromDateTime(
            (data['feedingTime1'] as Timestamp).toDate(),
          );
        }
        if (data['feedingTime2'] != null && data['feedingTime2'] is Timestamp) {
          feedingTime2 = TimeOfDay.fromDateTime(
            (data['feedingTime2'] as Timestamp).toDate(),
          );
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    Map<String, dynamic> data = {
      'feedingEnabled': isFeedingEnabled,
      'phBalancerEnabled': isPhBalancerEnabled,
    };

    if (isFeedingEnabled) {
      if (feedingTime1 != null) {
        data['feedingTime1'] = Timestamp.fromDate(
          _timeOfDayToDateTime(feedingTime1!),
        );
      }
      if (feedingTime2 != null) {
        data['feedingTime2'] = Timestamp.fromDate(
          _timeOfDayToDateTime(feedingTime2!),
        );
      }
    } else {
      data['feedingTime1'] = FieldValue.delete();
      data['feedingTime2'] = FieldValue.delete();
    }

    await docRef.set(data, SetOptions(merge: true));
  }

  DateTime _timeOfDayToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      bool isDuplicate =
          (index == 1 && picked == feedingTime2) ||
          (index == 2 && picked == feedingTime1);
      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feeding times cannot be the same.')),
        );
        return;
      }

      setState(() {
        if (index == 1) feedingTime1 = picked;
        if (index == 2) feedingTime2 = picked;
      });
      _saveSettings();
    }
  }

  void _resetTime(int index) {
    setState(() {
      if (index == 1) feedingTime1 = null;
      if (index == 2) feedingTime2 = null;
    });
    docRef.update({
      if (index == 1) 'feedingTime1': FieldValue.delete(),
      if (index == 2) 'feedingTime2': FieldValue.delete(),
    });
  }

  Widget _buildFeedingTimeTile(String label, TimeOfDay? time, int index) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontFamily: 'Lexend')),
      subtitle: Text(
        time != null ? time.format(context) : "Not set",
        style: const TextStyle(fontFamily: 'Lexend'),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: () => _pickTime(index),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _resetTime(index),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (selectedTabIndex == 0) {
      return Column(
        key: const ValueKey('feeding'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text(
              "Enable Feeding",
              style: TextStyle(fontFamily: 'Lexend'),
            ),
            subtitle: const Text(
              "Turn on automated feeding schedules.",
              style: TextStyle(fontFamily: 'Lexend'),
            ),
            value: isFeedingEnabled,
            activeColor: Colors.teal,
            onChanged: (value) {
              setState(() => isFeedingEnabled = value);
              _saveSettings();
            },
          ),
          if (isFeedingEnabled) ...[
            _buildFeedingTimeTile("Schedule 1", feedingTime1, 1),
            _buildFeedingTimeTile("Schedule 2", feedingTime2, 2),
          ],
        ],
      );
    } else {
      return Column(
        key: const ValueKey('ph'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text(
              "Enable pH Balancer",
              style: TextStyle(fontFamily: 'Lexend'),
            ),
            subtitle: const Text(
              "Automatically maintain optimal pH levels.",
              style: TextStyle(fontFamily: 'Lexend'),
            ),
            value: isPhBalancerEnabled,
            activeColor: Colors.teal,
            onChanged: (value) {
              setState(() => isPhBalancerEnabled = value);
              _saveSettings();
            },
          ),
          if (isPhBalancerEnabled)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Target pH Range: 6.8 - 7.2",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lexend',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "The system will automatically dose to keep the pH within this range.",
                    style: TextStyle(color: Colors.grey, fontFamily: 'Lexend'),
                  ),
                ],
              ),
            ),
        ],
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Automation Controls",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontFamily: 'Lexend'),
            ),
            const SizedBox(height: 4),
            Text(
              "Manage automated feeding and pH balancing.",
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'Lexend'),
            ),
            const SizedBox(height: 16),
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
                    isFeatureActive: isFeedingEnabled,
                  ),
                  _buildSegmentTab(
                    label: "pH Balancer",
                    index: 1,
                    isActive: selectedTabIndex == 1,
                    isFeatureActive: isPhBalancerEnabled,
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
                child: _buildTabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
