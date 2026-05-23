import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kDefaultBackgroundAsset = 'assets/images/hero-bg.jpg';

enum CriterionKind {
  numeric,
  category6,
  rating7,
  heroPreference7,
  availability2,
}

enum CriterionOptimization {
  maximize,
  minimize,
}

enum PreferenceFunction {
  usual,
  linear,
  quasi,
  linearQuasi,
  level,
  gaussian,
}

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
      PreferenceFunction.linearQuasi => 'Tipe IV — Linear Quasi (V-Shape Indifference)',
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
      optimization: CriterionOptimizationX.fromJson(json['optimization'] as String?),
      weight: (json['weight'] as num?)?.toDouble() ?? 1,
      function: PreferenceFunctionX.fromJson(json['function'] as String?),
      isCore: json['isCore'] as bool? ?? false,
    );
  }
}

class SkinDraft {
  const SkinDraft({
    required this.id,
    required this.name,
    required this.values,
  });

  final String id;
  final String name;
  final Map<String, double> values;

  SkinDraft copyWith({
    String? name,
    Map<String, double>? values,
  }) {
    return SkinDraft(
      id: id,
      name: name ?? this.name,
      values: values ?? this.values,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'values': values,
    };
  }

  factory SkinDraft.fromJson(Map<String, dynamic> json) {
    return SkinDraft(
      id: json['id'] as String? ?? 'skin',
      name: json['name'] as String? ?? '',
      values: (json['values'] as Map<String, dynamic>? ?? const <String, dynamic>{})
          .map((key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0)),
    );
  }
}

class SkinRankingRow {
  const SkinRankingRow({
    required this.rank,
    required this.skinId,
    required this.skinName,
    required this.leavingFlow,
    required this.enteringFlow,
    required this.netFlow,
    required this.recommended,
  });

  final int rank;
  final String skinId;
  final String skinName;
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
  static const _criteriaKey = 'skindecide.criteria';
  static const _skinsKey = 'skindecide.skins';
  static const _backgroundKey = 'skindecide.backgroundBase64';
  static const _backgroundNameKey = 'skindecide.backgroundName';
  static const _adminPasswordKey = 'skindecide.adminPassword';
  static const _adminLoginKey = 'skindecide.adminLoggedIn';

  late SharedPreferences _prefs;
  bool _ready = false;

  bool get ready => _ready;

  bool _isAdminLoggedIn = false;
  String _adminPassword = 'admin123';
  List<CriterionDefinition> _criteria = defaultCriteria();
  List<SkinDraft> _skins = <SkinDraft>[];
  List<SkinRankingRow> _results = <SkinRankingRow>[];
  String? _backgroundBase64;
  String? _backgroundName;

  bool get isAdminLoggedIn => _isAdminLoggedIn;
  String get adminDisplayName => 'Administrator';
  List<CriterionDefinition> get criteria => List.unmodifiable(_criteria);
  List<SkinDraft> get skins => List.unmodifiable(_skins);
  List<SkinRankingRow> get results => List.unmodifiable(_results);
  String? get backgroundName => _backgroundName;

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
    if (_results.isEmpty) {
      return;
    }
    _results = <SkinRankingRow>[];
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
    notifyListeners();
    unawaited(_persist());
  }

  void addSkin() {
    _skins = <SkinDraft>[
      ..._skins,
      _blankSkin(),
    ];
    _results = <SkinRankingRow>[];
    notifyListeners();
    unawaited(_persist());
  }

  void removeSkin(String skinId) {
    if (_skins.length <= 2) {
      return;
    }
    _skins = _skins.where((skin) => skin.id != skinId).toList(growable: false);
    _results = <SkinRankingRow>[];
    notifyListeners();
    unawaited(_persist());
  }

  void resetComparisonInputs() {
    _skins = _createDefaultSkins();
    _results = <SkinRankingRow>[];
    notifyListeners();
    unawaited(_persist());
  }

  void updateCriterion(CriterionDefinition updated) {
    final index = _criteria.indexWhere((criterion) => criterion.id == updated.id);
    if (index == -1) {
      return;
    }
    _criteria[index] = updated;
    _syncSkinsToCriteria();
    _results = <SkinRankingRow>[];
    notifyListeners();
    unawaited(_persist());
  }

  void addCriterion(CriterionDefinition criterion) {
    _criteria = <CriterionDefinition>[
      ..._criteria,
      criterion,
    ];
    _syncSkinsToCriteria();
    _results = <SkinRankingRow>[];
    notifyListeners();
    unawaited(_persist());
  }

  void removeCriterion(String criterionId) {
    _criteria = _criteria.where((criterion) => criterion.id != criterionId).toList(growable: false);
    _syncSkinsToCriteria();
    _results = <SkinRankingRow>[];
    notifyListeners();
    unawaited(_persist());
  }

  void resetCriteria() {
    _criteria = defaultCriteria();
    _syncSkinsToCriteria();
    _results = <SkinRankingRow>[];
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

  Future<bool> updateAdminPassword(String currentPassword, String newPassword) async {
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

  List<SkinRankingRow> calculateRanking() {
    if (_skins.isEmpty) {
      _results = <SkinRankingRow>[];
      notifyListeners();
      return _results;
    }

    final activeCriteria = _criteria.where((criterion) => criterion.weight > 0).toList(growable: false);
    final totalWeight = activeCriteria.fold<double>(0, (sum, criterion) => sum + criterion.weight);
    final comparisonCount = math.max(1, _skins.length - 1);
    final divisor = math.max(1, _criteria.length).toDouble();

    final workingRows = <_WorkingRow>[];
    for (final skin in _skins) {
      var leaving = 0.0;
      var entering = 0.0;

      for (final opponent in _skins) {
        if (skin.id == opponent.id) {
          continue;
        }

        leaving += _pairPreference(skin, opponent, activeCriteria, totalWeight);
        entering += _pairPreference(opponent, skin, activeCriteria, totalWeight);
      }

      final leavingFlow = leaving / comparisonCount / divisor;
      final enteringFlow = entering / comparisonCount / divisor;
      workingRows.add(
        _WorkingRow(
          skin: skin,
          leavingFlow: leavingFlow,
          enteringFlow: enteringFlow,
          netFlow: leavingFlow - enteringFlow,
        ),
      );
    }

    workingRows.sort((left, right) {
      final byNet = right.netFlow.compareTo(left.netFlow);
      if (byNet != 0) {
        return byNet;
      }
      return left.skin.name.toLowerCase().compareTo(right.skin.name.toLowerCase());
    });

    _results = [
      for (var index = 0; index < workingRows.length; index++)
        SkinRankingRow(
          rank: index + 1,
          skinId: workingRows[index].skin.id,
          skinName: workingRows[index].skin.name.trim().isEmpty ? 'Skin ${index + 1}' : workingRows[index].skin.name.trim(),
          leavingFlow: workingRows[index].leavingFlow,
          enteringFlow: workingRows[index].enteringFlow,
          netFlow: workingRows[index].netFlow,
          recommended: index == 0,
        ),
    ];
    notifyListeners();
    unawaited(_persist());
    return _results;
  }

  double _pairPreference(
    SkinDraft skin,
    SkinDraft opponent,
    List<CriterionDefinition> activeCriteria,
    double totalWeight,
  ) {
    if (totalWeight <= 0 || activeCriteria.isEmpty) {
      return 0;
    }

    var weightedScore = 0.0;
    for (final criterion in activeCriteria) {
      final skinValue = skin.values[criterion.id] ?? criterion.kind.defaultValue;
      final opponentValue = opponent.values[criterion.id] ?? criterion.kind.defaultValue;
      final normalizedAdvantage = _normalizedAdvantage(criterion, skinValue, opponentValue);
      final transformed = _applyPreferenceFunction(normalizedAdvantage, criterion.function);
      weightedScore += criterion.weight * transformed;
    }

    return weightedScore / totalWeight;
  }

  double _normalizedAdvantage(
    CriterionDefinition criterion,
    double skinValue,
    double opponentValue,
  ) {
    double rawDifference;

    if (criterion.kind == CriterionKind.numeric) {
      final values = _skins
          .map((skin) => skin.values[criterion.id] ?? 0)
          .toList(growable: false);
      final minimum = values.fold<double>(skinValue, math.min);
      final maximum = values.fold<double>(skinValue, math.max);
      final range = maximum - minimum;
      if (range <= 0) {
        return 0;
      }
      rawDifference = criterion.optimization == CriterionOptimization.maximize
          ? (skinValue - opponentValue) / range
          : (opponentValue - skinValue) / range;
    } else {
      final range = criterion.kind.domainRange;
      if (range <= 0) {
        return 0;
      }
      rawDifference = criterion.optimization == CriterionOptimization.maximize
          ? (skinValue - opponentValue) / range
          : (opponentValue - skinValue) / range;
    }

    return rawDifference.clamp(0.0, 1.0);
  }

  double _applyPreferenceFunction(double value, PreferenceFunction function) {
    return switch (function) {
      PreferenceFunction.usual => value > 0 ? 1 : 0,
      PreferenceFunction.linear => value,
      PreferenceFunction.quasi => value >= 0.35 ? 1 : 0,
      PreferenceFunction.linearQuasi => value <= 0.15 ? 0 : ((value - 0.15) / 0.85).clamp(0.0, 1.0),
      PreferenceFunction.level => value <= 0.2 ? 0 : value <= 0.6 ? 0.5 : 1,
      PreferenceFunction.gaussian => math.exp(-math.pow(1 - value, 2) / (2 * 0.25 * 0.25)),
    }
        .toDouble();
  }

  Future<void> _persist() async {
    if (!_ready) {
      return;
    }

    await _prefs.setString(
      _criteriaKey,
      jsonEncode(_criteria.map((criterion) => criterion.toJson()).toList(growable: false)),
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
      for (final criterion in _criteria) criterion.id: criterion.kind.defaultValue,
    };

    return SkinDraft(
      id: label ?? _uniqueId('skin'),
      name: '',
      values: values,
    );
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

class _WorkingRow {
  const _WorkingRow({
    required this.skin,
    required this.leavingFlow,
    required this.enteringFlow,
    required this.netFlow,
  });

  final SkinDraft skin;
  final double leavingFlow;
  final double enteringFlow;
  final double netFlow;
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