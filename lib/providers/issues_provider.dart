import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/issue.dart';
import '../models/comment.dart';
import '../services/issues_service.dart';

class IssuesProvider with ChangeNotifier {
  final IssuesService _issuesService = IssuesService();

  List<Issue> _issues = [];
  bool _isLoading = false;
  String? _error;
  Issue? _selectedIssue;
  List<Comment> _comments = [];

  List<Issue> get issues => _issues;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Issue? get selectedIssue => _selectedIssue;
  List<Comment> get comments => _comments;

  // Filters
  String? _selectedState;
  String? _selectedLga;
  IssueCategory? _selectedCategory;
  IssueStatus? _selectedStatus;
  String _sortBy = 'createdAt';
  bool _sortDescending = true;

  String? get selectedState => _selectedState;
  String? get selectedLga => _selectedLga;
  IssueCategory? get selectedCategory => _selectedCategory;
  IssueStatus? get selectedStatus => _selectedStatus;
  String get sortBy => _sortBy;
  bool get sortDescending => _sortDescending;

  void setFilters({
    String? state,
    String? lga,
    IssueCategory? category,
    IssueStatus? status,
  }) {
    _selectedState = state;
    _selectedLga = lga;
    _selectedCategory = category;
    _selectedStatus = status;
    loadIssues();
  }

  void setSorting(String sortBy, bool descending) {
    _sortBy = sortBy;
    _sortDescending = descending;
    loadIssues();
  }

  void loadIssues() {
    _isLoading = true;
    notifyListeners();

    _issuesService
        .getIssuesStream(
          state: _selectedState,
          lga: _selectedLga,
          category: _selectedCategory,
          status: _selectedStatus,
          sortBy: _sortBy,
          descending: _sortDescending,
        )
        .listen((issues) {
      _issues = issues;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> createIssue({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _issuesService.createIssue(
        title: title,
        description: description,
        category: category,
        state: state,
        lga: lga,
        userId: userId,
        userName: userName,
        isAnonymous: isAnonymous,
        images: images,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> selectIssue(String issueId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedIssue = await _issuesService.getIssue(issueId);
      if (_selectedIssue != null) {
        // Load comments
        _issuesService.getCommentsStream(issueId).listen((comments) {
          _comments = comments;
          notifyListeners();
        });
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> voteOnIssue(String issueId, String userId) async {
    try {
      await _issuesService.voteOnIssue(issueId, userId);

      // Update local issue
      if (_selectedIssue != null && _selectedIssue!.id == issueId) {
        final hasVoted = await _issuesService.hasUserVoted(issueId, userId);
        final currentVotes = _selectedIssue!.upvotes;
        _selectedIssue = _selectedIssue!.copyWith(
          upvotes: hasVoted ? currentVotes + 1 : currentVotes - 1,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addComment({
    required String issueId,
    required String userId,
    String? userName,
    bool isAnonymous = false,
    required String content,
  }) async {
    try {
      await _issuesService.addComment(
        issueId: issueId,
        userId: userId,
        userName: userName,
        isAnonymous: isAnonymous,
        content: content,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateIssueStatus({
    required String issueId,
    required IssueStatus newStatus,
    required String updatedBy,
    String? reason,
  }) async {
    try {
      await _issuesService.updateIssueStatus(
        issueId: issueId,
        newStatus: newStatus,
        updatedBy: updatedBy,
        reason: reason,
      );

      // Update local issue
      if (_selectedIssue != null && _selectedIssue!.id == issueId) {
        _selectedIssue = _selectedIssue!.copyWith(status: newStatus);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> hasUserVoted(String issueId, String userId) async {
    return await _issuesService.hasUserVoted(issueId, userId);
  }
}