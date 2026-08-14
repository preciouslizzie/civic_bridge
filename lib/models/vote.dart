class Vote {
  final String id;
  final String issueId;
  final String userId;
  final DateTime createdAt;

  Vote({
    required this.id,
    required this.issueId,
    required this.userId,
    required this.createdAt,
  });

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id'] ?? '',
      issueId: json['issueId'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issueId': issueId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}