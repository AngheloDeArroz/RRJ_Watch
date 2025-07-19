import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SystemStatusScreen extends StatefulWidget {
  const SystemStatusScreen({super.key});

  @override
  State<SystemStatusScreen> createState() => _SystemStatusScreenState();
}

class _SystemStatusScreenState extends State<SystemStatusScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('current-water-quality')
            .orderBy('lastUpdated', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty || !docs.first.data().containsKey('lastUpdated')) {
            return _buildStatusCard(
              isOnline: false,
              message: 'No valid data found.',
            );
          }

          final data = docs.first.data();
          final Timestamp lastUpdated = data['lastUpdated'];
          final Duration difference = _now.difference(lastUpdated.toDate());
          final bool isOnline = difference.inSeconds <= 20;

          final String formattedTime =
              DateFormat('yyyy-MM-dd • hh:mm:ss a').format(lastUpdated.toDate());

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Prototype Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    isOnline
                        ? 'assets/images/prototype_on.png'
                        : 'assets/images/prototype_off.png',
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 28),

                // Header
                const Text(
                  'Prototype Connection Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Lexend',
                  ),
                ),

                const SizedBox(height: 14),

                // Online/Offline Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.teal : Colors.redAccent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    isOnline ? 'ONLINE' : 'OFFLINE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lexend',
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Informational Note
                Text(
                  isOnline
                      ? 'The prototype is currently operating and communicating with the system.'
                      : 'The prototype appears to be offline. Check device power and internet connection.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Last Updated Timestamp
                Column(
                  children: [
                    const Text(
                      'Last Data Received:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Lexend',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard({required bool isOnline, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Lexend',
            ),
          ),
        ],
      ),
    );
  }
}
