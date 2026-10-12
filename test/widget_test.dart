import 'package:flutter_test/flutter_test.dart';

import 'package:wage_flow/services/salary_calculator.dart';
import 'package:wage_flow/models/worker.dart';

void main() {
  test('SalaryCalculator computes daily total', () {
    final w = Worker(
      name: 'RAJU',
      baseDailyRate: 650,
      otHourlyRate: 81.25,
      joiningDate: 0,
    );
    expect(
      SalaryCalculator.dailyTotal(worker: w, isPresent: 1, overTimeHours: 7),
      650 + 7 * 81.25,
    );
    expect(
      SalaryCalculator.dailyTotal(
          worker: w, isPresent: 0.5, overTimeHours: 0),
      325,
    );
  });
}
