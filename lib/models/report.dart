enum ReportType {
  spam,
  harassment,
  hateSpeech,
  inappropriate,
  other,
}

class Report {
  final String id;
  final String reportedItemId; // Issue or Comment ID
  final String reportedItemType; // 'issue' or 'comment'
  final String reporterId;
  final ReportType type;
  final String? description;
  final DateTime createdAt;
  final bool reviewed;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? actionTaken;

  Report({
    required this.id,
    required this.reportedItemId,
    required this.reportedItemType,
    required this.reporterId,
    required this.type,
    this.description,
    required this.createdAt,
    this.reviewed = false,
    this.reviewedBy,
    this.reviewedAt,
    this.actionTaken,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? '',
      reportedItemId: json['reportedItemId'] ?? '',
      reportedItemType: json['reportedItemType'] ?? '',
      reporterId: json['reporterId'] ?? '',
      type: ReportType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReportType.other,
      ),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      reviewed: json['reviewed'] ?? false,
      reviewedBy: json['reviewedBy'],
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt']) : null,
      actionTaken: json['actionTaken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportedItemId': reportedItemId,
      'reportedItemType': reportedItemType,
      'reporterId': reporterId,
      'type': type.name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'reviewed': reviewed,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'actionTaken': actionTaken,
    };
  }

  Report copyWith({
    String? id,
    String? reportedItemId,
    String? reportedItemType,
    String? reporterId,
    ReportType? type,
    String? description,
    DateTime? createdAt,
    bool? reviewed,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? actionTaken,
  }) {
    return Report(
      id: id ?? this.id,
      reportedItemId: reportedItemId ?? this.reportedItemId,
      reportedItemType: reportedItemType ?? this.reportedItemType,
      reporterId: reporterId ?? this.reporterId,
      type: type ?? this.type,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      reviewed: reviewed ?? this.reviewed,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      actionTaken: actionTaken ?? this.actionTaken,
    );
  }
}