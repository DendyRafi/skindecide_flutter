import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skindecide_flutter/app_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'SkinRecommendationApi posts to the local API and returns ranking results',
    () async {
      var calls = 0;
      final api = SkinRecommendationApi(
        client: MockClient((request) async {
          calls += 1;
          expect(request.url.scheme, 'http');
          expect(request.url.host, 'localhost');
          expect(request.url.port, 8000);
          expect(request.url.path, '/api/hitung-rekomendasi');
          expect(request.method, 'POST');
          expect(request.headers['Accept'], 'application/json');
          expect(request.headers['Content-Type'], 'application/json');

          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final alternatives = body['alternatives'] as List<dynamic>;
          expect(alternatives, hasLength(2));
          expect(
            (alternatives.first as Map<String, dynamic>)['scores'],
            containsPair('57', 1000),
          );
          expect(
            (alternatives.first as Map<String, dynamic>)['scores'],
            containsPair('64', 1),
          );

          return http.Response(
            jsonEncode(<String, Object?>{
              'status': 'success',
              'rekomendasi': <Map<String, Object?>>[
                <String, Object?>{
                  'name': 'Skin B',
                  'code': null,
                  'leaving_flow': 0.75,
                  'entering_flow': 0.25,
                  'net_flow': 0.5,
                  'rank': 1,
                },
                <String, Object?>{
                  'name': 'Skin A',
                  'code': null,
                  'leaving_flow': 0.25,
                  'entering_flow': 0.75,
                  'net_flow': -0.5,
                  'rank': 2,
                },
              ],
            }),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      final rows = await api.calculate(<SkinDraft>[
        SkinDraft(
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
        SkinDraft(
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

      expect(calls, 1);
      expect(rows.first.skinName, 'Skin B');
      expect(rows.first.rank, 1);
      expect(rows.first.netFlow, 0.5);
      expect(rows.first.recommended, isTrue);
    },
  );

  test(
    'SkinRecommendationApi does not retry HTTP after API-level errors',
    () async {
      var calls = 0;
      final api = SkinRecommendationApi(
        client: MockClient((request) async {
          calls += 1;
          return http.Response(
            jsonEncode(<String, Object?>{
              'status': 'error',
              'message': 'Data alternatif tidak valid.',
            }),
            422,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      await expectLater(
        api.calculate(<SkinDraft>[_completeSkin('skin-a', 'Skin A')]),
        throwsA(
          isA<SkinRecommendationException>().having(
            (error) => error.message,
            'message',
            'Data alternatif tidak valid.',
          ),
        ),
      );
      expect(calls, 1);
    },
  );

  test(
    'SkinRecommendationApi reports API connection failure when the local endpoint fails',
    () async {
      var calls = 0;
      final api = SkinRecommendationApi(
        client: MockClient((request) async {
          calls += 1;
          throw http.ClientException('network blocked', request.url);
        }),
      );

      await expectLater(
        api.calculate(<SkinDraft>[_completeSkin('skin-a', 'Skin A')]),
        throwsA(
          isA<SkinRecommendationException>().having(
            (error) => error.message,
            'message',
            'Gagal memproses rekomendasi. Periksa koneksi atau server API.',
          ),
        ),
      );
      expect(calls, 1);
    },
  );

  test(
    'SkinRecommendationApi displays top tied results with rank one',
    () async {
      final api = SkinRecommendationApi(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode(<String, Object?>{
              'status': 'success',
              'rekomendasi': <Map<String, Object?>>[
                <String, Object?>{
                  'name': 'Skin A',
                  'code': null,
                  'leaving_flow': 0.5,
                  'entering_flow': 0.5,
                  'net_flow': 0.0,
                  'rank': 1,
                },
                <String, Object?>{
                  'name': 'Skin B',
                  'code': null,
                  'leaving_flow': 0.5,
                  'entering_flow': 0.5,
                  'net_flow': 0.0,
                  'rank': 2,
                },
              ],
            }),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      final rows = await api.calculate(<SkinDraft>[
        _completeSkin('skin-a', 'Skin A'),
        _completeSkin('skin-b', 'Skin B'),
      ]);

      expect(rows.map((row) => row.rank), everyElement(1));
      expect(rows.map((row) => row.recommended), everyElement(isTrue));
    },
  );

  test(
    'SkinRecommendationApi fails explicitly when a score is missing',
    () async {
      final api = SkinRecommendationApi(
        client: MockClient((request) async {
          fail('request should not be sent when scores are incomplete');
        }),
      );

      await expectLater(
        api.calculate(<SkinDraft>[
          const SkinDraft(
            id: 'skin-a',
            name: 'Skin A',
            values: <String, double>{},
          ),
        ]),
        throwsA(isA<SkinRecommendationException>()),
      );
    },
  );

  test(
    'SkinRecommendationApi fails explicitly on malformed recommendation rows',
    () async {
      final api = SkinRecommendationApi(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode(<String, Object?>{
              'status': 'success',
              'rekomendasi': <Object?>['bad-row'],
            }),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      await expectLater(
        api.calculate(<SkinDraft>[_completeSkin('skin-a', 'Skin A')]),
        throwsA(
          isA<SkinRecommendationException>().having(
            (error) => error.message,
            'message',
            'Format data rekomendasi API tidak dikenali.',
          ),
        ),
      );
    },
  );

  test('AppController stores API ranking results after calculation', () async {
    final controller = AppController(
      recommendationApi: SkinRecommendationApi(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode(<String, Object?>{
              'status': 'success',
              'rekomendasi': <Map<String, Object?>>[
                <String, Object?>{
                  'name': 'Skin 1',
                  'code': null,
                  'leaving_flow': 0.6,
                  'entering_flow': 0.2,
                  'net_flow': 0.4,
                  'rank': 1,
                },
                <String, Object?>{
                  'name': 'Skin 2',
                  'code': null,
                  'leaving_flow': 0.2,
                  'entering_flow': 0.6,
                  'net_flow': -0.4,
                  'rank': 2,
                },
              ],
            }),
            200,
          );
        }),
      ),
    );
    await controller.load();
    controller
      ..updateSkin(
        controller.skins[0].copyWith(
          name: 'Skin 1',
          values: <String, double>{
            ...controller.skins[0].values,
            'price': 1000,
          },
        ),
      )
      ..updateSkin(
        controller.skins[1].copyWith(
          name: 'Skin 2',
          values: <String, double>{
            ...controller.skins[1].values,
            'price': 2000,
          },
        ),
      );

    await controller.calculateRanking();

    expect(controller.calculationError, isNull);
    expect(controller.results, hasLength(2));
    expect(controller.results.first.skinName, 'Skin 1');
    expect(controller.results.first.leavingFlow, 0.6);
  });
}

SkinDraft _completeSkin(String id, String name) {
  return SkinDraft(
    id: id,
    name: name,
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
  );
}
