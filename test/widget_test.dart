import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_compass/compass/compass_screen.dart';
import 'package:pocket_compass/main.dart';

void main() {
  testWidgets('App shows compass screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PocketCompassApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(CompassScreen), findsOneWidget);
  });
}
