import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';
import '../utils/constants.dart';
import 'firebase_service.dart';

class ModerationService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;

  // Report Content
  Future<void> reportContent({
    required String reportedItemId,
    required String reportedItemType, // 'issue' or 'comment'
    required String reporterId,
    required ReportType type,
    String? description,
  }) async {
    final reportId = _firestore.collection(AppConstants.reportsCollection).doc().id;

    final report = Report(
      id: reportId,
      reportedItemId: reportedItemId,
      reportedItemType: reportedItemType,
      reporterId: reporterId,
      type: type,
      description: description,
      createdAt: DateTime.now(),
    );

    await _firestore.collection(AppConstants.reportsCollection).doc(reportId).set(report.toJson());
  }

  // Get Reports Stream (Admin)
  Stream<List<Report>> getReportsStream({bool onlyUnreviewed = true}) {
    Query query = _firestore.collection(AppConstants.reportsCollection);

    if (onlyUnreviewed) {
      query = query.where('reviewed', isEqualTo: false);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Report.fromJson(doc.data() as Map<String, dynamic>)).toList());
  }

  // Review Report
  Future<void> reviewReport({
    required String reportId,
    required String reviewedBy,
    required String actionTaken,
  }) async {
    await _firestore.collection(AppConstants.reportsCollection).doc(reportId).update({
      'reviewed': true,
      'reviewedBy': reviewedBy,
      'reviewedAt': DateTime.now().toIso8601String(),
      'actionTaken': actionTaken,
    });
  }

  // Basic Content Moderation (Simple keyword filtering)
  bool containsInappropriateContent(String content) {
    final inappropriateWords = [
      'spam',
      'abuse',
      'hate',
      'racist',
      'sexist',
      'violent',
      // Add more words as needed
    ];

    final lowerContent = content.toLowerCase();
    return inappropriateWords.any((word) => lowerContent.contains(word));
  }

  // Check if content should be flagged
  Future<bool> shouldFlagContent(String content) async {
    // Basic checks
    if (containsInappropriateContent(content)) {
      return true;
    }

    // Could add more sophisticated checks here (AI-based, etc.)
    return false;
  }
}