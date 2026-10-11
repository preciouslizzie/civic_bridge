import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/issue.dart';
import '../models/user.dart';
import '../models/report.dart';
import 'firebase_service.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;

  // Issue management
  Future<List<Issue>> getAllIssues({
    IssueStatus? status,
    String? category,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection('issues');

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Issue.fromJson(doc.data())).toList();
  }

  Future<void> updateIssueStatus({
    required String issueId,
    required IssueStatus newStatus,
    required String updatedBy,
    String? reason,
  }) async {
    await _firestore.collection('issues').doc(issueId).update({
      'status': newStatus.name,
      'updatedBy': updatedBy,
      'updatedAt': Timestamp.now(),
      'moderationNote': ?reason,
    });
  }

  Future<void> deleteIssue(String issueId) async {
    await _firestore.collection('issues').doc(issueId).delete();
  }

  // User management
  Future<List<User>> getAllUsers({int limit = 100}) async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => User.fromJson(doc.data())).toList();
  }

  Future<void> suspendUser(String userId, String reason) async {
    await _firestore.collection('users').doc(userId).update({
      'isSuspended': true,
      'suspendedAt': Timestamp.now(),
      'suspensionReason': reason,
    });
  }

  Future<void> unsuspendUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isSuspended': false,
      'suspendedAt': null,
      'suspensionReason': null,
    });
  }

  Future<void> makeModerator(String userId) async {
    await _firestore.collection('moderators').doc(userId).set({
      'userId': userId,
      'assignedAt': Timestamp.now(),
      'assignedBy': 'admin', // Replace with actual admin ID
    });
  }

  Future<void> removeModerator(String userId) async {
    await _firestore.collection('moderators').doc(userId).delete();
  }

  // Report management
  Future<List<Report>> getAllReports({
    String? status,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection('reports');

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Report.fromJson(doc.data())).toList();
  }

  Future<void> reviewReport({
    required String reportId,
    required String status,
    required String reviewedBy,
    String? reviewNote,
  }) async {
    await _firestore.collection('reports').doc(reportId).update({
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewedAt': Timestamp.now(),
      'reviewNote': ?reviewNote,
    });
  }

  // Analytics
  Future<Map<String, dynamic>> getAnalytics() async {
    final issuesStats = await _getIssuesStats();
    final usersStats = await _getUsersStats();
    final reportsStats = await _getReportsStats();

    return {
      'issues': issuesStats,
      'users': usersStats,
      'reports': reportsStats,
      'generatedAt': Timestamp.now(),
    };
  }

  Future<Map<String, dynamic>> _getIssuesStats() async {
    final snapshot = await _firestore.collection('issues').get();

    int totalIssues = snapshot.docs.length;
    int resolvedIssues = 0;
    int pendingIssues = 0;
    int flaggedIssues = 0;

    Map<String, int> issuesByCategory = {};
    Map<String, int> issuesByState = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'];
      final category = data['category'];
      final state = data['state'];

      if (status == 'resolved') resolvedIssues++;
      if (status == 'pending') pendingIssues++;
      if (status == 'flagged') flaggedIssues++;

      issuesByCategory[category] = (issuesByCategory[category] ?? 0) + 1;
      issuesByState[state] = (issuesByState[state] ?? 0) + 1;
    }

    return {
      'total': totalIssues,
      'resolved': resolvedIssues,
      'pending': pendingIssues,
      'flagged': flaggedIssues,
      'byCategory': issuesByCategory,
      'byState': issuesByState,
    };
  }

  Future<Map<String, dynamic>> _getUsersStats() async {
    final snapshot = await _firestore.collection('users').get();

    int totalUsers = snapshot.docs.length;
    int activeUsers = 0;
    int suspendedUsers = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['isSuspended'] == true) {
        suspendedUsers++;
      } else {
        activeUsers++;
      }
    }

    return {
      'total': totalUsers,
      'active': activeUsers,
      'suspended': suspendedUsers,
    };
  }

  Future<Map<String, dynamic>> _getReportsStats() async {
    final snapshot = await _firestore.collection('reports').get();

    int totalReports = snapshot.docs.length;
    int pendingReports = 0;
    int reviewedReports = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['status'] == 'pending') {
        pendingReports++;
      } else {
        reviewedReports++;
      }
    }

    return {
      'total': totalReports,
      'pending': pendingReports,
      'reviewed': reviewedReports,
    };
  }

  // Bulk operations
  Future<void> bulkUpdateIssueStatus({
    required List<String> issueIds,
    required IssueStatus newStatus,
    required String updatedBy,
  }) async {
    final batch = _firestore.batch();

    for (String issueId in issueIds) {
      final ref = _firestore.collection('issues').doc(issueId);
      batch.update(ref, {
        'status': newStatus.name,
        'updatedBy': updatedBy,
        'updatedAt': Timestamp.now(),
      });
    }

    await batch.commit();
  }

  // Configuration management
  Future<Map<String, dynamic>> getAppConfig() async {
    final doc = await _firestore.collection('config').doc('app').get();
    return doc.exists ? doc.data()! : {};
  }

  Future<void> updateAppConfig(Map<String, dynamic> config) async {
    await _firestore.collection('config').doc('app').set(config, SetOptions(merge: true));
  }

  // Admin role management
  Future<List<String>> getAdminIds() async {
    final snapshot = await _firestore.collection('admins').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<List<String>> getModeratorIds() async {
    final snapshot = await _firestore.collection('moderators').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<void> addAdmin(String userId) async {
    await _firestore.collection('admins').doc(userId).set({
      'userId': userId,
      'assignedAt': Timestamp.now(),
      'assignedBy': 'system', // Replace with actual admin ID
    });
  }

  Future<void> removeAdmin(String userId) async {
    await _firestore.collection('admins').doc(userId).delete();
  }
}