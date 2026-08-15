// Smoke test for the app's root widget.
//
// The full app cannot be pumped in a plain widget test because main() calls
// Firebase.initializeApp() before runApp(). This test therefore only verifies
// that the root widget still constructs, which is enough to catch the class
// being renamed or removed.

import 'package:flutter_test/flutter_test.dart';

import 'package:bens_ways/main.dart';

void main() {
  test('BensWayApp can be constructed', () {
    expect(const BensWayApp(), isNotNull);
  });
}
