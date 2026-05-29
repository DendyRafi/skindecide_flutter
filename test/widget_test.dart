import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:skindecide_flutter/app_controller.dart';
import 'package:skindecide_flutter/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders the SkinDecide home screen', (
    WidgetTester tester,
  ) async {
    final controller = AppController();
    await controller.load();

    await tester.pumpWidget(
      SkindecideScope(
        controller: controller,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Tambah Pilihan Skin'), findsOneWidget);
    expect(find.text('HITUNG REKOMENDASI'), findsOneWidget);
  });
}
