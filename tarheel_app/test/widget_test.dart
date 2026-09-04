import 'package:flutter_test/flutter_test.dart';
import 'package:tarheel_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TarheelApp());
    expect(find.text('تـرحـيـل'), findsOneWidget);
  });
}
