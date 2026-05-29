import 'package:flutter_test/flutter_test.dart';
import 'package:skindecide_flutter/app_controller.dart';

void main() {
  test('live pikskinmlbb API returns PROMETHEE recommendation JSON', () async {
    final api = SkinRecommendationApi();
    final rows = await api.calculate(<SkinDraft>[
      const SkinDraft(
        id: 'skin-a',
        name: 'Skin A',
        values: <String, double>{
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
      const SkinDraft(
        id: 'skin-b',
        name: 'Skin B',
        values: <String, double>{
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
    ]);

    expect(rows, hasLength(2));
    expect(rows.first.rank, 1);
    expect(rows.first.skinName, 'Skin B');
    expect(rows.first.netFlow, 0.5);
  });
}
