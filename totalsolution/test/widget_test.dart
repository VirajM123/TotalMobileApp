import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totalsolution/main.dart';
import 'package:totalsolution/screens/auth/login_screen.dart' show LoginScreen;

void main() {
  testWidgets('Signed-out app opens the login form', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Sign In'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
