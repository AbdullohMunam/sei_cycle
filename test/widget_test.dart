import 'package:flutter_test/flutter_test.dart';
import 'package:sei_cycle/core/constants/farm_modules.dart';

void main() {
  test('five default farm modules are available', () {
    expect(FarmModules.values, hasLength(5));
    expect(FarmModules.values.map((module) => module.id), contains('lele'));
  });
}
