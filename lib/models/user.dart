class User {
  final String id;
  final String name;
  final String phoneNumber;
  final String state;
  final String lga;
  final bool anonymousPosting;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.state,
    required this.lga,
    this.anonymousPosting = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      state: json['state'] ?? '',
      lga: json['lga'] ?? '',
      anonymousPosting: json['anonymousPosting'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'state': state,
      'lga': lga,
      'anonymousPosting': anonymousPosting,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? state,
    String? lga,
    bool? anonymousPosting,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      state: state ?? this.state,
      lga: lga ?? this.lga,
      anonymousPosting: anonymousPosting ?? this.anonymousPosting,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}