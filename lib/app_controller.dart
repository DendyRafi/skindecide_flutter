import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart' as crypto;
import 'package:shared_preferences/shared_preferences.dart';

import 'recommendation_http_client.dart';

const String kDefaultBackgroundAsset = 'assets/images/hero-bg.jpg';
const String _recommendationFailureMessage =
    'Gagal memproses rekomendasi. Periksa koneksi atau server API.';
enum CriterionKind {
  numeric,
  category6,
  rating7,
  heroPreference7,
  availability2,
}

enum CriterionOptimization { maximize, minimize }

enum PreferenceFunction { usual, linear, quasi, linearQuasi, level, gaussian }

extension CriterionKindX on CriterionKind {
  double get domainRange {
    return switch (this) {
      CriterionKind.numeric => 0,
      CriterionKind.category6 => 5,
      CriterionKind.rating7 => 6,
      CriterionKind.heroPreference7 => 6,
      CriterionKind.availability2 => 1,
    };
  }

  double get defaultValue {
    return switch (this) {
      CriterionKind.numeric => 0,
      CriterionKind.category6 => 1,
      CriterionKind.rating7 => 4,
      CriterionKind.heroPreference7 => 4,
      CriterionKind.availability2 => 1,
    };
  }

  String get displayLabel {
    return switch (this) {
      CriterionKind.numeric => 'Angka',
      CriterionKind.category6 => 'Kategori',
      CriterionKind.rating7 => 'Skala 1-7',
      CriterionKind.heroPreference7 => 'Preferensi Hero',
      CriterionKind.availability2 => 'Ketersediaan',
    };
  }

  static CriterionKind fromJson(String? value) {
    return CriterionKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => CriterionKind.rating7,
    );
  }
}

extension CriterionOptimizationX on CriterionOptimization {
  String get displayLabel {
    return switch (this) {
      CriterionOptimization.maximize => 'Maximize (▲)',
      CriterionOptimization.minimize => 'Minimize (▼)',
    };
  }

  static CriterionOptimization fromJson(String? value) {
    return CriterionOptimization.values.firstWhere(
      (optimization) => optimization.name == value,
      orElse: () => CriterionOptimization.maximize,
    );
  }
}

extension PreferenceFunctionX on PreferenceFunction {
  String get displayLabel {
    return switch (this) {
      PreferenceFunction.usual => 'Tipe I — Usual (Biasa)',
      PreferenceFunction.linear => 'Tipe II — Linear (V-Shape)',
      PreferenceFunction.quasi => 'Tipe III — Quasi (U-Shape)',
      PreferenceFunction.linearQuasi =>
        'Tipe IV — Linear Quasi (V-Shape Indifference)',
      PreferenceFunction.level => 'Tipe V — Level (Tingkat)',
      PreferenceFunction.gaussian => 'Tipe VI — Gaussian',
    };
  }

  static PreferenceFunction fromJson(String? value) {
    return PreferenceFunction.values.firstWhere(
      (function) => function.name == value,
      orElse: () => PreferenceFunction.usual,
    );
  }
}

class CriterionDefinition {
  const CriterionDefinition({
    required this.id,
    required this.label,
    required this.kind,
    required this.optimization,
    required this.weight,
    required this.function,
    required this.isCore,
  });

  final String id;
  final String label;
  final CriterionKind kind;
  final CriterionOptimization optimization;
  final double weight;
  final PreferenceFunction function;
  final bool isCore;

  CriterionDefinition copyWith({
    String? label,
    CriterionKind? kind,
    CriterionOptimization? optimization,
    double? weight,
    PreferenceFunction? function,
    bool? isCore,
  }) {
    return CriterionDefinition(
      id: id,
      label: label ?? this.label,
      kind: kind ?? this.kind,
      optimization: optimization ?? this.optimization,
      weight: weight ?? this.weight,
      function: function ?? this.function,
      isCore: isCore ?? this.isCore,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'kind': kind.name,
      'optimization': optimization.name,
      'weight': weight,
      'function': function.name,
      'isCore': isCore,
    };
  }

  factory CriterionDefinition.fromJson(Map<String, dynamic> json) {
    return CriterionDefinition(
      id: json['id'] as String? ?? 'criterion',
      label: json['label'] as String? ?? 'Kriteria',
      kind: CriterionKindX.fromJson(json['kind'] as String?),
      optimization: CriterionOptimizationX.fromJson(
        json['optimization'] as String?,
      ),
      weight: (json['weight'] as num?)?.toDouble() ?? 1,
      function: PreferenceFunctionX.fromJson(json['function'] as String?),
      isCore: json['isCore'] as bool? ?? false,
    );
  }
}

class SkinDraft {
  const SkinDraft({required this.id, required this.name, required this.values});

  final String id;
  final String name;
  final Map<String, double> values;

  SkinDraft copyWith({String? name, Map<String, double>? values}) {
    return SkinDraft(
      id: id,
      name: name ?? this.name,
      values: values ?? this.values,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'name': name, 'values': values};
  }

  factory SkinDraft.fromJson(Map<String, dynamic> json) {
    return SkinDraft(
      id: json['id'] as String? ?? 'skin',
      name: json['name'] as String? ?? '',
      values:
          (json['values'] as Map<String, dynamic>? ?? const <String, dynamic>{})
              .map(
                (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0),
              ),
    );
  }
}

class SkinRankingRow {
  const SkinRankingRow({
    required this.rank,
    required this.skinId,
    required this.skinName,
    this.code,
    required this.leavingFlow,
    required this.enteringFlow,
    required this.netFlow,
    required this.recommended,
  });

  final int rank;
  final String skinId;
  final String skinName;
  final String? code;
  final double leavingFlow;
  final double enteringFlow;
  final double netFlow;
  final bool recommended;
}

List<CriterionDefinition> defaultCriteria() {
  return <CriterionDefinition>[
    const CriterionDefinition(
      id: 'price',
      label: 'Harga (Diamond)',
      kind: CriterionKind.numeric,
      optimization: CriterionOptimization.minimize,
      weight: 1,
      function: PreferenceFunction.usual,
      isCore: true,
    ),
    const CriterionDefinition(
      id: 'category',
      label: 'Kategori Skin',
      kind: CriterionKind.category6,
      optimization: CriterionOptimization.maximize,
      weight: 1,
      function: PreferenceFunction.usual,
      isCore: true,
    ),
    const CriterionDefinition(
      id: 'model',
      label: 'Model Skin',
      kind: CriterionKind.rating7,
      optimization: CriterionOptimization.maximize,
      weight: 1,
      function: PreferenceFunction.usual,
      isCore: true,
    ),
    const CriterionDefinition(
      id: 'portrait',
      label: 'Portrait Skin',
      kind: CriterionKind.rating7,
      optimization: CriterionOptimization.maximize,
      weight: 1,
      function: PreferenceFunction.usual,
      isCore: true,
    ),
    const CriterionDefinition(
      id: 'entrance',
      label: 'Animasi Entrance',
      kind: CriterionKind.rating7,
      optimization: CriterionOptimization.maximize,
      weight: 1,
      function: PreferenceFunction.usual,
      isCore: true,
    ),
    const CriterionDefinition(
      id: 'effect',
      label: 'In-Game Effect',
      kind: CriterionKind.rating7,
      optimization: CriterionOptimization.maximize,
      weight: 1,
      function: PreferenceFunction.usual,
      isCore: true,
    ),
    const CriterionDefinition(
      id: 'heroPreference',
      label: 'Tingkat Preferensi Hero',
      kind: CriterionKind.heroPreference7,
      optimization: CriterionOptimization.maximize,
      weight: 1,
      function: PreferenceFunction.usual,
      isCore: true,
    ),
    const CriterionDefinition(
      id: 'availability',
      label: 'Status Ketersediaan Skin',
      kind: CriterionKind.availability2,
      optimization: CriterionOptimization.minimize,
      weight: 1,
      function: PreferenceFunction.usual,
      isCore: true,
    ),
  ];
}

class AppController extends ChangeNotifier {
  AppController({SkinRecommendationApi? recommendationApi})
    : _recommendationApi = recommendationApi ?? SkinRecommendationApi();

  static const _criteriaKey = 'skindecide.criteria';
  static const _skinsKey = 'skindecide.skins';
  static const _backgroundKey = 'skindecide.backgroundBase64';
  static const _backgroundNameKey = 'skindecide.backgroundName';
  static const _adminPasswordKey = 'skindecide.adminPassword';
  static const _adminLoginKey = 'skindecide.adminLoggedIn';

  final SkinRecommendationApi _recommendationApi;

  late SharedPreferences _prefs;
  bool _ready = false;

  bool get ready => _ready;

  bool _isAdminLoggedIn = false;
  bool _isCalculating = false;
  String _adminPassword = 'admin123';
  List<CriterionDefinition> _criteria = defaultCriteria();
  List<SkinDraft> _skins = <SkinDraft>[];
  List<SkinRankingRow> _results = <SkinRankingRow>[];
  String? _backgroundBase64;
  String? _backgroundName;
  String? _calculationError;

  bool get isAdminLoggedIn => _isAdminLoggedIn;
  bool get isCalculating => _isCalculating;
  String get adminDisplayName => 'Administrator';
  List<CriterionDefinition> get criteria => List.unmodifiable(_criteria);
  List<SkinDraft> get skins => List.unmodifiable(_skins);
  List<SkinRankingRow> get results => List.unmodifiable(_results);
  String? get backgroundName => _backgroundName;
  String? get calculationError => _calculationError;

  static AppController of(BuildContext context) {
    return SkindecideScope.of(context);
  }

  ImageProvider<Object> get backgroundImageProvider {
    final data = _backgroundBase64;
    if (data == null || data.isEmpty) {
      return const AssetImage(kDefaultBackgroundAsset);
    }

    try {
      return MemoryImage(base64Decode(data));
    } on FormatException {
      return const AssetImage(kDefaultBackgroundAsset);
    }
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _adminPassword = _prefs.getString(_adminPasswordKey) ?? 'admin123';
    _isAdminLoggedIn = _prefs.getBool(_adminLoginKey) ?? false;
    _backgroundBase64 = _prefs.getString(_backgroundKey);
    _backgroundName = _prefs.getString(_backgroundNameKey);

    _criteria = _loadCriteria() ?? defaultCriteria();
    _skins = _loadSkins() ?? _createDefaultSkins();
    _syncSkinsToCriteria();
    _ready = true;
    notifyListeners();
  }

  void clearResults() {
    if (_results.isEmpty && _calculationError == null) {
      return;
    }
    _results = <SkinRankingRow>[];
    _calculationError = null;
    notifyListeners();
    unawaited(_persist());
  }

  void updateSkin(SkinDraft updated) {
    final synced = _syncSingleSkin(updated);
    final index = _skins.indexWhere((skin) => skin.id == synced.id);
    if (index == -1) {
      return;
    }
    _skins[index] = synced;
    _results = <SkinRankingRow>[];
    _calculationError = null;
    notifyListeners();
    unawaited(_persist());
  }

  void addSkin() {
    _skins = <SkinDraft>[..._skins, _blankSkin()];
    _results = <SkinRankingRow>[];
    _calculationError = null;
    notifyListeners();
    unawaited(_persist());
  }

  void removeSkin(String skinId) {
    if (_skins.length <= 2) {
      return;
    }
    _skins = _skins.where((skin) => skin.id != skinId).toList(growable: false);
    _results = <SkinRankingRow>[];
    _calculationError = null;
    notifyListeners();
    unawaited(_persist());
  }

  void resetComparisonInputs() {
    _skins = _createDefaultSkins();
    _results = <SkinRankingRow>[];
    _calculationError = null;
    notifyListeners();
    unawaited(_persist());
  }

  void updateCriterion(CriterionDefinition updated) {
    final index = _criteria.indexWhere(
      (criterion) => criterion.id == updated.id,
    );
    if (index == -1) {
      return;
    }
    _criteria[index] = updated;
    _syncSkinsToCriteria();
    _results = <SkinRankingRow>[];
    _calculationError = null;
    notifyListeners();
    unawaited(_persist());
  }

  void addCriterion(CriterionDefinition criterion) {
    _criteria = <CriterionDefinition>[..._criteria, criterion];
    _syncSkinsToCriteria();
    _results = <SkinRankingRow>[];
    _calculationError = null;
    notifyListeners();
    unawaited(_persist());
  }

  void removeCriterion(String criterionId) {
    _criteria = _criteria
        .where((criterion) => criterion.id != criterionId)
        .toList(growable: false);
    _syncSkinsToCriteria();
    _results = <SkinRankingRow>[];
    _calculationError = null;
    notifyListeners();
    unawaited(_persist());
  }

  void resetCriteria() {
    _criteria = defaultCriteria();
    _syncSkinsToCriteria();
    _results = <SkinRankingRow>[];
    _calculationError = null;
    notifyListeners();
    unawaited(_persist());
  }

  Future<bool> loginAdmin(
    String username,
    String password, {
    required bool rememberSession,
  }) async {
    if (username.trim() != 'admin' || password != _adminPassword) {
      return false;
    }

    _isAdminLoggedIn = true;
    if (rememberSession) {
      await _prefs.setBool(_adminLoginKey, true);
    } else {
      await _prefs.remove(_adminLoginKey);
    }
    notifyListeners();
    return true;
  }

  Future<void> logoutAdmin() async {
    _isAdminLoggedIn = false;
    await _prefs.remove(_adminLoginKey);
    notifyListeners();
  }

  Future<bool> updateAdminPassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (currentPassword != _adminPassword) {
      return false;
    }

    _adminPassword = newPassword;
    await _prefs.setString(_adminPasswordKey, newPassword);
    notifyListeners();
    return true;
  }

  Future<void> setBackgroundImage(String fileName, List<int> bytes) async {
    _backgroundName = fileName;
    _backgroundBase64 = base64Encode(bytes);
    await _prefs.setString(_backgroundNameKey, fileName);
    await _prefs.setString(_backgroundKey, _backgroundBase64!);
    notifyListeners();
  }

  Future<void> resetBackground() async {
    _backgroundName = null;
    _backgroundBase64 = null;
    await _prefs.remove(_backgroundNameKey);
    await _prefs.remove(_backgroundKey);
    notifyListeners();
  }

  String? validateComparisonInputs() {
    if (_skins.length < 2) {
      return 'Tambahkan minimal dua skin untuk dibandingkan.';
    }

    for (var index = 0; index < _skins.length; index++) {
      final skin = _skins[index];
      if (skin.name.trim().isEmpty) {
        return 'Lengkapi nama skin pada SKIN ${index + 1}.';
      }

      final price = skin.values['price'] ?? 0;
      if (price <= 0) {
        return 'Lengkapi harga diamond pada SKIN ${index + 1}.';
      }
    }

    return null;
  }

  Future<List<SkinRankingRow>> calculateRanking() async {
    if (_skins.isEmpty) {
      _results = <SkinRankingRow>[];
      _calculationError = null;
      notifyListeners();
      return _results;
    }

    _isCalculating = true;
    _calculationError = null;
    notifyListeners();

    try {
      final rows = await _recommendationApi.calculate(_skins);
      _results = rows;
      unawaited(_persist());
      return _results;
    } on SkinRecommendationException catch (error) {
      _results = <SkinRankingRow>[];
      _calculationError = error.message;
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Unexpected recommendation error: $error\n$stackTrace');
      _results = <SkinRankingRow>[];
      _calculationError = _recommendationFailureMessage;
      throw const SkinRecommendationException(_recommendationFailureMessage);
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    if (!_ready) {
      return;
    }

    await _prefs.setString(
      _criteriaKey,
      jsonEncode(
        _criteria
            .map((criterion) => criterion.toJson())
            .toList(growable: false),
      ),
    );
    await _prefs.setString(
      _skinsKey,
      jsonEncode(_skins.map((skin) => skin.toJson()).toList(growable: false)),
    );
    await _prefs.setString(_adminPasswordKey, _adminPassword);
    await _prefs.setBool(_adminLoginKey, _isAdminLoggedIn);

    if (_backgroundBase64 != null) {
      await _prefs.setString(_backgroundKey, _backgroundBase64!);
      if (_backgroundName != null) {
        await _prefs.setString(_backgroundNameKey, _backgroundName!);
      }
    } else {
      await _prefs.remove(_backgroundKey);
      await _prefs.remove(_backgroundNameKey);
    }
  }

  List<CriterionDefinition>? _loadCriteria() {
    final raw = _prefs.getString(_criteriaKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .cast<Map<String, dynamic>>()
          .map(CriterionDefinition.fromJson)
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  List<SkinDraft>? _loadSkins() {
    final raw = _prefs.getString(_skinsKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .cast<Map<String, dynamic>>()
          .map(SkinDraft.fromJson)
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  List<SkinDraft> _createDefaultSkins() {
    return <SkinDraft>[
      _blankSkin(label: 'skin_1'),
      _blankSkin(label: 'skin_2'),
    ];
  }

  SkinDraft _blankSkin({String? label}) {
    final values = <String, double>{
      for (final criterion in _criteria)
        criterion.id: criterion.kind.defaultValue,
    };

    return SkinDraft(id: label ?? _uniqueId('skin'), name: '', values: values);
  }

  SkinDraft _syncSingleSkin(SkinDraft skin) {
    final syncedValues = <String, double>{
      for (final criterion in _criteria)
        criterion.id: skin.values.containsKey(criterion.id)
            ? _clampCriterionValue(criterion, skin.values[criterion.id]!)
            : criterion.kind.defaultValue,
    };

    return skin.copyWith(values: syncedValues);
  }

  void _syncSkinsToCriteria() {
    _skins = [for (final skin in _skins) _syncSingleSkin(skin)];
  }

  double _clampCriterionValue(CriterionDefinition criterion, double value) {
    if (criterion.kind == CriterionKind.numeric) {
      return value >= 0 ? value : 0;
    }

    final minimum = criterion.kind == CriterionKind.availability2 ? 1 : 1;
    final maximum = switch (criterion.kind) {
      CriterionKind.numeric => value,
      CriterionKind.category6 => 6,
      CriterionKind.rating7 => 7,
      CriterionKind.heroPreference7 => 7,
      CriterionKind.availability2 => 2,
    };

    return value.clamp(minimum.toDouble(), maximum.toDouble());
  }

  String _uniqueId(String prefix) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return '${prefix}_$stamp';
  }
}

class SkinRecommendationException implements Exception {
  const SkinRecommendationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SkinRecommendationApi {
  SkinRecommendationApi({http.Client? client})
    : _client = client ?? createRecommendationHttpClient();

  static final Uri _endpoint = Uri.http(
    'pikskinmlbb.gamer.gd',
    // 'localhost:8000',
    '/api/hitung-rekomendasi',
  );

  static const Map<String, String> _serverCriteriaIds = <String, String>{
    'price': '1',
    'category': '2',
    'model': '3',
    'portrait': '4',
    'entrance': '5',
    'effect': '6',
    'heroPreference': '7',
    'availability': '8',
  };

  final http.Client _client;

  Future<List<SkinRankingRow>> calculate(List<SkinDraft> skins) async {
    final body = jsonEncode(<String, Object?>{
      'alternatives': [for (final skin in skins) _toApiAlternative(skin)],
    });

    try {
      return await _postRecommendation(_endpoint, body);
    } on TimeoutException {
      throw const SkinRecommendationException(_recommendationFailureMessage);
    } on http.ClientException {
      throw const SkinRecommendationException(_recommendationFailureMessage);
    }
  }

  Map<String, Object?> _toApiAlternative(SkinDraft skin) {
    final scores = <String, double>{};
    for (final entry in _serverCriteriaIds.entries) {
      final score = skin.values[entry.key];
      if (score == null) {
        throw SkinRecommendationException(
          'Nilai kriteria ${entry.key} untuk ${skin.name} belum lengkap.',
        );
      }
      scores[entry.value] = score;
    }

    return <String, Object?>{'name': skin.name, 'scores': scores};
  }

  Future<List<SkinRankingRow>> _postRecommendation(
    Uri endpoint,
    String body,
  ) async {
    var response = await _post(endpoint, body);

    for (var attempt = 0; attempt < 3; attempt += 1) {
      final challenge = _HostingChallenge.tryParse(response.body);
      if (challenge == null) {
        break;
      }

      final redirectUri = challenge.redirectUri(endpoint);
      final cookieValue = challenge.cookieValue;
      if (!canSetCookieHeader &&
          !storeHostingCookie(redirectUri, cookieValue)) {
        throw const SkinRecommendationException(
          'Browser tidak bisa menyetel cookie challenge untuk API lintas-domain.',
        );
      }

      response = await _post(
        redirectUri,
        body,
        cookieHeader: canSetCookieHeader ? '__test=$cookieValue' : null,
      );
    }

    final decoded = _decodeJson(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SkinRecommendationException(
        decoded['message'] as String? ?? 'Gagal memproses rekomendasi.',
      );
    }

    if (decoded['status'] != 'success') {
      throw SkinRecommendationException(
        decoded['message'] as String? ?? 'Terjadi kesalahan sistem.',
      );
    }

    final rekomendasi = decoded['rekomendasi'];
    if (rekomendasi is! List) {
      throw const SkinRecommendationException(
        'Respons API tidak memuat hasil rekomendasi.',
      );
    }

    final items = <Map<String, dynamic>>[];
    for (final item in rekomendasi) {
      if (item is! Map<String, dynamic>) {
        throw const SkinRecommendationException(
          'Format data rekomendasi API tidak dikenali.',
        );
      }
      items.add(item);
    }

    final topNetFlow = items.fold<double?>(null, (current, item) {
      final netFlow = (item['net_flow'] as num?)?.toDouble();
      if (netFlow == null) {
        return current;
      }
      return current == null || netFlow > current ? netFlow : current;
    });

    return <SkinRankingRow>[
      for (final item in items) _toRankingRow(item, topNetFlow),
    ];
  }

  SkinRankingRow _toRankingRow(Map<String, dynamic> item, double? topNetFlow) {
    final netFlow = (item['net_flow'] as num?)?.toDouble() ?? 0;
    final isTopTie =
        topNetFlow != null && (netFlow - topNetFlow).abs() < 0.0001;

    return SkinRankingRow(
      rank: isTopTie ? 1 : (item['rank'] as num?)?.toInt() ?? 0,
      skinId: (item['code'] as String?) ?? (item['name'] as String? ?? ''),
      skinName: item['name'] as String? ?? 'Skin',
      code: item['code'] as String?,
      leavingFlow: (item['leaving_flow'] as num?)?.toDouble() ?? 0,
      enteringFlow: (item['entering_flow'] as num?)?.toDouble() ?? 0,
      netFlow: netFlow,
      recommended: isTopTie,
    );
  }

  Future<http.Response> _post(
    Uri endpoint,
    String body, {
    String? cookieHeader,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (canSetCookieHeader) {
      headers
        ..['User-Agent'] = 'Mozilla/5.0 (SkinDecide Flutter)'
        ..['Connection'] = 'close';
      if (cookieHeader != null) {
        headers['Cookie'] = cookieHeader;
      }
    }

    return _client
        .post(endpoint, headers: headers, body: body)
        .timeout(const Duration(seconds: 20));
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      throw const SkinRecommendationException(
        'Respons API bukan JSON. Server mungkin sedang memblokir client aplikasi.',
      );
    }

    throw const SkinRecommendationException(
      'Format respons API tidak dikenali.',
    );
  }
}

class _HostingChallenge {
  const _HostingChallenge({
    required this.keyHex,
    required this.ivHex,
    required this.cipherHex,
    required this.location,
  });

  final String keyHex;
  final String ivHex;
  final String cipherHex;
  final String location;

  String get cookieValue {
    final cipher = crypto.CBCBlockCipher(crypto.AESEngine())
      ..init(
        false,
        crypto.ParametersWithIV<crypto.KeyParameter>(
          crypto.KeyParameter(_hexToBytes(keyHex)),
          _hexToBytes(ivHex),
        ),
      );
    final encrypted = _hexToBytes(cipherHex);
    final output = Uint8List(encrypted.length);

    for (
      var offset = 0;
      offset < encrypted.length;
      offset += cipher.blockSize
    ) {
      cipher.processBlock(encrypted, offset, output, offset);
    }

    return _bytesToHex(output);
  }

  Uri redirectUri(Uri fallback) {
    if (location.isEmpty) {
      throw const SkinRecommendationException(
        'Tantangan hosting API tidak memuat target redirect.',
      );
    }

    return fallback.resolve(location);
  }

  static _HostingChallenge? tryParse(String body) {
    if (!body.contains('slowAES.decrypt') ||
        !body.contains('document.cookie="__test="')) {
      return null;
    }

    final hexValues = RegExp(
      r'toNumbers\("([0-9a-fA-F]+)"\)',
    ).allMatches(body).map((match) => match.group(1)!).toList(growable: false);
    final location =
        RegExp(r'location\.href="([^"]+)"').firstMatch(body)?.group(1) ?? '';

    if (hexValues.length < 3) {
      return null;
    }

    return _HostingChallenge(
      keyHex: hexValues[0],
      ivHex: hexValues[1],
      cipherHex: hexValues[2],
      location: location,
    );
  }

  static Uint8List _hexToBytes(String hex) {
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return bytes;
  }

  static String _bytesToHex(Uint8List bytes) {
    const digits = '0123456789abcdef';
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer
        ..write(digits[(byte >> 4) & 0x0f])
        ..write(digits[byte & 0x0f]);
    }
    return buffer.toString();
  }
}

class SkindecideScope extends InheritedNotifier<AppController> {
  const SkindecideScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SkindecideScope>();
    assert(scope != null, 'SkindecideScope not found in context');
    return scope!.notifier!;
  }
}
