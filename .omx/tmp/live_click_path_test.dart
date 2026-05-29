import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skindecide_flutter/app_controller.dart';

void main() {
  test('live click path through AppController calculates ranking', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = AppController();
    await controller.load();
    controller
      ..updateSkin(
        controller.skins[0].copyWith(
          name: 'Skin A',
          values: <String, double>{
            ...controller.skins[0].values,
            'price': 1000,
            'category': 1,
            'model': 4,
            'portrait': 4,
            'entrance': 4,
            'effect': 4,
            'heroPreference': 4,
            'availability': 1,
          },
        ),
      )
      ..updateSkin(
        controller.skins[1].copyWith(
          name: 'Skin B',
          values: <String, double>{
            ...controller.skins[1].values,
            'price': 2000,
            'category': 2,
            'model': 5,
            'portrait': 5,
            'entrance': 5,
            'effect': 5,
            'heroPreference': 5,
            'availability': 2,
          },
        ),
      );

    final rows = await controller.calculateRanking();
    print('calculationError=${controller.calculationError}');
    print('rows=${rows.map((row) => '${row.rank}:${row.skinName}:${row.netFlow}').join(',')}');

    expect(controller.calculationError, isNull);
    expect(rows, hasLength(2));
    expect(rows.first.skinName, 'Skin B');
  });
}
