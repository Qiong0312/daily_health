import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_health/app.dart';
import 'package:daily_health/providers/health_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Bloom shows loading then app shell', (WidgetTester tester) async {
    final provider = HealthProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const BloomApp(),
      ),
    );

    expect(find.text('Bloom'), findsOneWidget);

    await provider.init();
    await tester.pump();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Track your cycle'), findsOneWidget);
  });
}
