class Comment {
  final String id;
  final String issueId;
  final String userId;
  final String? userName;
  final bool isAnonymous;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.issueId,
    required this.userId,
    this.userName,
    this.isAnonymous = false,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      issueId: json['issueId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'],
      isAnonymous: json['isAnonymous'] ?? false,
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issueId': issueId,
      'userId': userId,
      'userName': userName,
      'isAnonymous': isAnonymous,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Comment copyWith({
    String? id,
    String? issueId,
    String? userId,
    String? userName,
    bool? isAnonymous,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      issueId: issueId ?? this.issueId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}