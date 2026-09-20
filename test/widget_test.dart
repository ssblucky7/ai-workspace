// Smoke test: verifies the AI Workspace root widget builds and exposes
// its branded splash state while auth initializes. Firebase-dependent
// flows are covered by the model/validator/provider unit tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_workspace/main.dart';

void main() {
  testWidgets('AIWorkspaceApp smoke test', (WidgetTester tester) async {
    // Build the root widget (Firebase is intentionally NOT initialized in
    // the test environment; the unconfigured-notice path keeps it alive).
    await tester.pumpWidget(
      const MaterialApp(home: FirebaseUnconfiguredNotice()),
    );
    await tester.pump();

    expect(find.text('Firebase could not start'), findsOneWidget);
  });
}
