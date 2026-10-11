import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/issue.dart';
import '../models/comment.dart';
import '../models/vote.dart';
import '../utils/constants.dart';
import 'firebase_service.dart';

class IssuesService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;
  final FirebaseStorage _storage = FirebaseService().storage;

  // Create Issue
  Future<String> createIssue({
    required String title,
    required String description,
    required IssueCategory category,
    required String state,
    required String lga,
    required String userId,
    String? userName,
    bool isAnonymous = false,
    List<File>? images,
  }) async {
    final issueId = _firestore.collection(AppConstants.issuesCollection).doc().id;

    List<String> imageUrls = [];
    if (images != null && images.isNotEmpty) {
      imageUrls = await _uploadImages(issueId, images);
    }

    final issue = Issue(
      id: issueId,
      title: title,
      description: description,
      category: category,
      state: state,
      lga: lga,
      userId: userId,
      userName: userName,
      isAnonymous: isAnonymous,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection(AppConstants.issuesCollection).doc(issueId).set(issue.toJson());
    return issueId;
  }

  // Upload Images
  Future<List<String>> _uploadImages(String issueId, List<File> images) async {
    List<String> urls = [];
    for (int i = 0; i < images.length; i++) {
      final fileName = '${issueId}_$i.jpg';
      final ref = _storage.ref().child('${AppConstants.issueImagesPath}/$fileName');
      await ref.putFile(images[i]);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  // Get Issues Stream
  Stream<List<Issue>> getIssuesStream({
    String? state,
    String? lga,
    IssueCategory? category,
    IssueStatus? status,
    String sortBy = 'createdAt', // 'createdAt', 'upvotes'
    bool descending = true,
  }) {
    Query query = _firestore.collection(AppConstants.issuesCollection);

    if (state != null) {
      query = query.where('state', isEqualTo: state);
    }
    if (lga != null) {
      query = query.where('lga', isEqualTo: lga);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query
        .orderBy(sortBy, descending: descending)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Issue.fromJson(doc.data() as Map<String, dynamic>)).toList());
  }

  // Get Single Issue
  Future<Issue?> getIssue(String issueId) async {
    final doc = await _firestore.collection(AppConstants.issuesCollection).doc(issueId).get();
    if (doc.exists) {
      return Issue.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Update Issue Status
  Future<void> updateIssueStatus({
    required String issueId,
    required IssueStatus newStatus,
    required String updatedBy,
    String? reason,
  }) async {
    final statusUpdate = StatusUpdate(
      status: newStatus,
      updatedBy: updatedBy,
      reason: reason,
      timestamp: DateTime.now(),
    );

    await _firestore.collection(AppConstants.issuesCollection).doc(issueId).update({
      'status': newStatus.name,
      'updatedAt': DateTime.now().toIso8601String(),
      'statusHistory': FieldValue.arrayUnion([statusUpdate.toJson()]),
    });
  }

  // Vote on Issue
  Future<void> voteOnIssue(String issueId, String userId) async {
    final voteId = '${issueId}_$userId';
    final voteRef = _firestore.collection(AppConstants.votesCollection).doc(voteId);

    final voteDoc = await voteRef.get();
    if (voteDoc.exists) {
      // Remove vote
      await voteRef.delete();
      await _firestore.collection(AppConstants.issuesCollection).doc(issueId).update({
        'upvotes': FieldValue.increment(-1),
      });
    } else {
      // Add vote
      final vote = Vote(
        id: voteId,
        issueId: issueId,
        userId: userId,
        createdAt: DateTime.now(),
      );
      await voteRef.set(vote.toJson());
      await _firestore.collection(AppConstants.issuesCollection).doc(issueId).update({
        'upvotes': FieldValue.increment(1),
      });
    }
  }

  // Check if user voted
  Future<bool> hasUserVoted(String issueId, String userId) async {
    final voteId = '${issueId}_$userId';
    final voteDoc = await _firestore.collection(AppConstants.votesCollection).doc(voteId).get();
    return voteDoc.exists;
  }

  // Get Comments Stream
  Stream<List<Comment>> getCommentsStream(String issueId) {
    return _firestore
        .collection(AppConstants.commentsCollection)
        .where('issueId', isEqualTo: issueId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Comment.fromJson(doc.data())).toList());
  }

  // Add Comment
  Future<String> addComment({
    required String issueId,
    required String userId,
    String? userName,
    bool isAnonymous = false,
    required String content,
  }) async {
    final commentId = _firestore.collection(AppConstants.commentsCollection).doc().id;

    final comment = Comment(
      id: commentId,
      issueId: issueId,
      userId: userId,
      userName: userName,
      isAnonymous: isAnonymous,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection(AppConstants.commentsCollection).doc(commentId).set(comment.toJson());

    // Update comment count
    await _firestore.collection(AppConstants.issuesCollection).doc(issueId).update({
      'commentCount': FieldValue.increment(1),
    });

    return commentId;
  }

  // Delete Issue (Admin only)
  Future<void> deleteIssue(String issueId) async {
    // Get issue to delete images
    final issue = await getIssue(issueId);
    if (issue != null && issue.imageUrls.isNotEmpty) {
      await _deleteImages(issue.imageUrls);
    }

    // Delete comments
    final comments = await _firestore
        .collection(AppConstants.commentsCollection)
        .where('issueId', isEqualTo: issueId)
        .get();

    for (final doc in comments.docs) {
      await doc.reference.delete();
    }

    // Delete votes
    final votes = await _firestore
        .collection(AppConstants.votesCollection)
        .where('issueId', isEqualTo: issueId)
        .get();

    for (final doc in votes.docs) {
      await doc.reference.delete();
    }

    // Delete issue
    await _firestore.collection(AppConstants.issuesCollection).doc(issueId).delete();
  }

  // Delete Images
  Future<void> _deleteImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      } catch (e) {
        debugPrint('Error deleting image: $e');
      }
    }
  }
}