import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/container_levels.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Real-time water quality stream (current)
  Stream<DocumentSnapshot<Map<String, dynamic>>> getCurrentWaterQuality() {
    return _db.collection('current-water-quality').doc('live').snapshots();
  }

  // Stream for last 24 hourly records
  Stream<QuerySnapshot<Map<String, dynamic>>> getHourlyWaterTrends() {
    return _db
        .collection('hourly-water-quality')
        .orderBy('timestamp', descending: true)
        .limit(24)
        .snapshots();
  }

  // One-time fetch for container levels
  Future<ContainerLevels?> fetchContainerLevels() async {
    final doc = await _db.collection('container-levels').doc('status').get();

    if (doc.exists && doc.data() != null) {
      return ContainerLevels.fromFirestore(doc.data()!);
    } else {
      return null;
    }
  }

  // Real-time stream for container levels
  Stream<ContainerLevels?> streamContainerLevels() {
    return _db
        .collection('container-levels')
        .doc('status')
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (snapshot.exists && data != null) {
        return ContainerLevels.fromFirestore(data);
      } else {
        return null;
      }
    });
  }
}
