import 'package:atmina_pos/src/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('يعرض الواجهة الرئيسية للتطبيق', (tester) async {
    SharedPreferences.setMockInitialValues({'atmina_app_role': 'merchant'});

    await tester.pumpWidget(
      const ProviderScope(
        child: AtminaApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Atmina POS'), findsWidgets);
    expect(find.text('المنتجات'), findsOneWidget);
  });
}
