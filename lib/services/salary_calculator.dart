import '../models/worker.dart';

class SalaryCalculator {
  /// Daily total = (isPresent * baseRate) + (OT hours * OT rate)
  static double dailyTotal({
    required Worker worker,
    required double isPresent,
    required double overTimeHours,
  }) {
    final base = isPresent * worker.baseDailyRate;
    final ot = overTimeHours * worker.otHourlyRate;
    return _round2(base + ot);
  }

  static double netPayable({
    required double totalEarned,
    required double totalUpad,
  }) => _round2(totalEarned - totalUpad);

  static double _round2(double v) => (v * 100).roundToDouble() / 100;
}
