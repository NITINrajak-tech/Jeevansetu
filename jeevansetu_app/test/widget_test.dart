import 'package:flutter_test/flutter_test.dart';
import 'package:jeevansetu_app/features/monitoring/providers/sensor_monitor_provider.dart';

void main() {
  test('crash threshold is 2.5 G (~25 m/s²)', () {
    expect(kCrashGForceThreshold, 25.0);
  });
}
