class AppSettings {
  final String displayName;
  final String email;
  final bool notificationsEnabled;

  const AppSettings({
    required this.displayName,
    required this.email,
    required this.notificationsEnabled,
  });

  factory AppSettings.initial() {
    return const AppSettings(
      displayName: 'Người dùng',
      email: 'user@example.com',
      notificationsEnabled: true,
    );
  }

  AppSettings copyWith({
    String? displayName,
    String? email,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'email': email,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final dynamic notificationsValue = json['notificationsEnabled'];

    return AppSettings(
      displayName: (json['displayName'] ?? 'Người dùng').toString(),
      email: (json['email'] ?? 'user@example.com').toString(),
      notificationsEnabled: notificationsValue is bool
          ? notificationsValue
          : notificationsValue.toString().toLowerCase() == 'true',
    );
  }
}
