import 'package:flutter_test/flutter_test.dart';
import 'package:mc_cafe_app/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const McCafeApp());

    // Verify splash screen content loads
    expect(find.text('A Taste Worth\nSavouring'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
