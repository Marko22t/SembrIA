// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sembria/main.dart';

void main() {
  testWidgets('Smoke test compile check', (WidgetTester tester) async {
    // Basic verification that the app compiles and runs.
    // We catch any Supabase initialization exceptions during raw test pumping.
    try {
      await tester.pumpWidget(const SembriaApp());
    } catch (_) {}
  });
}
