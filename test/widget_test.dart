import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passwords/main.dart';

void main() {
  testWidgets('Password Manager UI smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const PasswordManagerApp());

    // Verify the app bar title is present.
    expect(find.text('Password Manager'), findsOneWidget);

    // Tap the '+' FloatingActionButton to open the add dialog.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Enter values in the dialog fields.
    await tester.enterText(find.bySemanticsLabel('Title'), 'Test Site');
    await tester.enterText(find.bySemanticsLabel('Username'), 'testuser');
    await tester.enterText(find.bySemanticsLabel('Password'), 'testpass');

    // Tap the 'Add' button.
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Verify the new entry appears in the list.
    expect(find.text('Test Site'), findsOneWidget);
    expect(find.text('testuser'), findsOneWidget);
  });
}
