import 'package:flutter_test/flutter_test.dart';
import 'package:day_record/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const DayRecordApp());
    expect(find.text('每日成長與\n開發實踐紀錄'), findsOneWidget);
  });
}
