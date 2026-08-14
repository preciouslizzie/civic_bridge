enum IssueCategory {
  roads,
  electricity,
  water,
  security,
  health,
  education,
  environment,
  transportation,
  sanitation,
  other,
}

enum IssueStatus {
  reported,
  inProgress,
  resolved,
  archived,
}

class Issue {
  final String id;
  final String title;
  final String description;
  final IssueCategory category;
  final String state;
  final String lga;
  final String userId;
  final String? userName;
  final bool isAnonymous;
  final List<String> imageUrls;
  final IssueStatus status;
  final int upvotes;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StatusUpdate> statusHistory;

  Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.state,
    required this.lga,
    required this.userId,
    this.userName,
    this.isAnonymous = false,
    this.imageUrls = const [],
    this.status = IssueStatus.reported,
    this.upvotes = 0,
    this.commentCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.statusHistory = const [],
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: IssueCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => IssueCategory.other,
      ),
      state: json['state'] ?? '',
      lga: json['lga'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'],
      isAnonymous: json['isAnonymous'] ?? false,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      status: IssueStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => IssueStatus.reported,
      ),
      upvotes: json['upvotes'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      statusHistory: (json['statusHistory'] as List<dynamic>?)
          ?.map((e) => StatusUpdate.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'state': state,
      'lga': lga,
      'userId': userId,
      'userName': userName,
      'isAnonymous': isAnonymous,
      'imageUrls': imageUrls,
      'status': status.name,
      'upvotes': upvotes,
      'commentCount': commentCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'statusHistory': statusHistory.map((e) => e.toJson()).toList(),
    };
  }

  Issue copyWith({
    String? id,
    String? title,
    String? description,
    IssueCategory? category,
    String? state,
    String? lga,
    String? userId,
    String? userName,
    bool? isAnonymous,
    List<String>? imageUrls,
    IssueStatus? status,
    int? upvotes,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<StatusUpdate>? statusHistory,
  }) {
    return Issue(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      state: state ?? this.state,
      lga: lga ?? this.lga,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      upvotes: upvotes ?? this.upvotes,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }
}

class StatusUpdate {
  final IssueStatus status;
  final String updatedBy;
  final String? reason;
  final DateTime timestamp;

  StatusUpdate({
    required this.status,
    required this.updatedBy,
    this.reason,
    required this.timestamp,
  });

  factory StatusUpdate.fromJson(Map<String, dynamic> json) {
    return StatusUpdate(
      status: IssueStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => IssueStatus.reported,
      ),
      updatedBy: json['updatedBy'] ?? '',
      reason: json['reason'],
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'updatedBy': updatedBy,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}