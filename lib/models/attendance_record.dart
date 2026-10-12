class AttendanceRecord {
  final int? recordId;
  final int workerId;
  final int date; // epoch ms, normalized to midnight
  final double isPresent; // 1.0 = Full, 0.5 = Half, 0 = Absent
  final double overTimeHours;
  final double upadAmount;
  final String paymentMethod; // GPAY | CASH | ''
  final String remarks;
  final double calculatedTotal;
  final int settledAt; // 0 = unsettled; else epoch ms when "Settle & Reset" was applied

  AttendanceRecord({
    this.recordId,
    required this.workerId,
    required this.date,
    required this.isPresent,
    required this.overTimeHours,
    required this.upadAmount,
    required this.paymentMethod,
    required this.remarks,
    required this.calculatedTotal,
    this.settledAt = 0,
  });

  bool get isSettled => settledAt > 0;

  AttendanceRecord copyWith({
    int? recordId,
    double? isPresent,
    double? overTimeHours,
    double? upadAmount,
    String? paymentMethod,
    String? remarks,
    double? calculatedTotal,
    int? settledAt,
  }) => AttendanceRecord(
    recordId: recordId ?? this.recordId,
    workerId: workerId,
    date: date,
    isPresent: isPresent ?? this.isPresent,
    overTimeHours: overTimeHours ?? this.overTimeHours,
    upadAmount: upadAmount ?? this.upadAmount,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    remarks: remarks ?? this.remarks,
    calculatedTotal: calculatedTotal ?? this.calculatedTotal,
    settledAt: settledAt ?? this.settledAt,
  );

  Map<String, dynamic> toMap() => {
    'recordId': recordId,
    'workerId': workerId,
    'date': date,
    'isPresent': isPresent,
    'overTimeHours': overTimeHours,
    'upadAmount': upadAmount,
    'paymentMethod': paymentMethod,
    'remarks': remarks,
    'calculatedTotal': calculatedTotal,
    'settledAt': settledAt,
  };

  factory AttendanceRecord.fromMap(Map<String, dynamic> m) => AttendanceRecord(
    recordId: m['recordId'] as int?,
    workerId: m['workerId'] as int,
    date: m['date'] as int,
    isPresent: (m['isPresent'] as num).toDouble(),
    overTimeHours: (m['overTimeHours'] as num).toDouble(),
    upadAmount: (m['upadAmount'] as num).toDouble(),
    paymentMethod: (m['paymentMethod'] as String?) ?? '',
    remarks: (m['remarks'] as String?) ?? '',
    calculatedTotal: (m['calculatedTotal'] as num).toDouble(),
    settledAt: (m['settledAt'] as int?) ?? 0,
  );
}
