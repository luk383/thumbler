class NotificationSettings {
  const NotificationSettings({
    required this.studyReminderEnabled,
    required this.studyReminderTime,
    required this.streakProtectionEnabled,
    required this.streakProtectionTime,
  });

  final bool studyReminderEnabled;
  final String studyReminderTime; // "HH:mm" format
  final bool streakProtectionEnabled;
  final String streakProtectionTime; // "HH:mm" format

  static NotificationSettings get defaults => const NotificationSettings(
        studyReminderEnabled: false,
        studyReminderTime: '08:00',
        streakProtectionEnabled: false,
        streakProtectionTime: '20:00',
      );

  NotificationSettings copyWith({
    bool? studyReminderEnabled,
    String? studyReminderTime,
    bool? streakProtectionEnabled,
    String? streakProtectionTime,
  }) =>
      NotificationSettings(
        studyReminderEnabled:
            studyReminderEnabled ?? this.studyReminderEnabled,
        studyReminderTime: studyReminderTime ?? this.studyReminderTime,
        streakProtectionEnabled:
            streakProtectionEnabled ?? this.streakProtectionEnabled,
        streakProtectionTime:
            streakProtectionTime ?? this.streakProtectionTime,
      );

  Map<String, dynamic> toMap() => {
        'studyReminderEnabled': studyReminderEnabled,
        'studyReminderTime': studyReminderTime,
        'streakProtectionEnabled': streakProtectionEnabled,
        'streakProtectionTime': streakProtectionTime,
      };

  factory NotificationSettings.fromMap(Map map) => NotificationSettings(
        studyReminderEnabled:
            map['studyReminderEnabled'] as bool? ?? false,
        studyReminderTime:
            map['studyReminderTime'] as String? ?? '08:00',
        streakProtectionEnabled:
            map['streakProtectionEnabled'] as bool? ?? false,
        streakProtectionTime:
            map['streakProtectionTime'] as String? ?? '20:00',
      );
}
