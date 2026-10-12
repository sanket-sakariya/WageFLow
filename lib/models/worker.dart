class Worker {
  final int? id;
  final String name;
  final String role;
  final double baseDailyRate;
  final double otHourlyRate;
  final int joiningDate; // epoch ms
  final bool isActive;

  Worker({
    this.id,
    required this.name,
    this.role = '',
    required this.baseDailyRate,
    required this.otHourlyRate,
    required this.joiningDate,
    this.isActive = true,
  });

  Worker copyWith({
    int? id,
    String? name,
    String? role,
    double? baseDailyRate,
    double? otHourlyRate,
    int? joiningDate,
    bool? isActive,
  }) => Worker(
    id: id ?? this.id,
    name: name ?? this.name,
    role: role ?? this.role,
    baseDailyRate: baseDailyRate ?? this.baseDailyRate,
    otHourlyRate: otHourlyRate ?? this.otHourlyRate,
    joiningDate: joiningDate ?? this.joiningDate,
    isActive: isActive ?? this.isActive,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'role': role,
    'baseDailyRate': baseDailyRate,
    'otHourlyRate': otHourlyRate,
    'joiningDate': joiningDate,
    'isActive': isActive ? 1 : 0,
  };

  factory Worker.fromMap(Map<String, dynamic> m) => Worker(
    id: m['id'] as int?,
    name: m['name'] as String,
    role: (m['role'] as String?) ?? '',
    baseDailyRate: (m['baseDailyRate'] as num).toDouble(),
    otHourlyRate: (m['otHourlyRate'] as num).toDouble(),
    joiningDate: m['joiningDate'] as int,
    isActive: (m['isActive'] as int) == 1,
  );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
