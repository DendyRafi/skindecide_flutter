import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_controller.dart';
import 'shared_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _resultsKey = GlobalKey();

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _calculate() {
    final controller = AppController.of(context);
    final validation = controller.validateComparisonInputs();
    if (validation != null) {
      _showMessage(validation);
      return;
    }

    controller.calculateRanking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resultContext = _resultsKey.currentContext;
      if (resultContext != null) {
        Scrollable.ensureVisible(
          resultContext,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          alignment: 0.08,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppController.of(context);

    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(
                      onSettings: () =>
                          Navigator.of(context).pushNamed('/pengaturan'),
                    ),
                    const SizedBox(height: 26),
                    const _HeroSection(),
                    const SizedBox(height: 24),
                    for (
                      var index = 0;
                      index < controller.skins.length;
                      index++
                    ) ...[
                      SkinCardEditor(
                        key: ValueKey(controller.skins[index].id),
                        index: index,
                        skin: controller.skins[index],
                        criteria: controller.criteria,
                        onChanged: controller.updateSkin,
                        onRemove: () =>
                            controller.removeSkin(controller.skins[index].id),
                        canRemove: controller.skins.length > 2,
                      ),
                      if (index != controller.skins.length - 1)
                        const SizedBox(height: 18),
                    ],
                    const SizedBox(height: 18),
                    NeonSecondaryButton(
                      label: 'Tambah Pilihan Skin',
                      icon: Icons.add_rounded,
                      expand: true,
                      onPressed: controller.addSkin,
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 320;
                        if (narrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              NeonSecondaryButton(
                                label: 'Hapus Input Tersimpan',
                                icon: Icons.delete_outline_rounded,
                                expand: true,
                                onPressed: controller.resetComparisonInputs,
                              ),
                              const SizedBox(height: 10),
                              NeonPrimaryButton(
                                label: 'Hitung Rekomendasi',
                                icon: Icons.analytics_rounded,
                                expand: true,
                                onPressed: _calculate,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: NeonSecondaryButton(
                                label: 'Hapus Input Tersimpan',
                                icon: Icons.delete_outline_rounded,
                                expand: true,
                                onPressed: controller.resetComparisonInputs,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: NeonPrimaryButton(
                                label: 'Hitung Rekomendasi',
                                icon: Icons.analytics_rounded,
                                expand: true,
                                onPressed: _calculate,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    if (controller.results.isNotEmpty)
                      ResultPanel(
                        key: _resultsKey,
                        results: controller.results,
                      ),
                    const SizedBox(height: 28),
                    const _Footer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const AppBrand(size: 21),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassActionButton(
                label: 'PENGATURAN',
                icon: Icons.tune_rounded,
                onTap: onSettings,
              ),
              const SizedBox(width: 10),
              const GlassTag(
                label: 'PROMETHEE TEAM',
                fontSize: 9.5,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'SKINDECIDE - ASISTEN REKOMENDASI SKIN',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: kAccentGreen,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Rekomendasi Skin Terbaik',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: kTextPrimary,
            letterSpacing: 0.5,
            fontSize: 26,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Masukkan nama skin yang ingin dibandingkan beserta penilaian kriteria kamu',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: kTextPrimary.withOpacity(0.9),
            height: 1.5,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '(Masukkan Skala 1-7, khusus Kategori masukkan skala 1-6, dan untuk Harga masukkan dalam jumlah Diamond)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: kTextMuted.withOpacity(0.85),
            height: 1.5,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

class SkinCardEditor extends StatefulWidget {
  const SkinCardEditor({
    super.key,
    required this.index,
    required this.skin,
    required this.criteria,
    required this.onChanged,
    required this.onRemove,
    required this.canRemove,
  });

  final int index;
  final SkinDraft skin;
  final List<CriterionDefinition> criteria;
  final ValueChanged<SkinDraft> onChanged;
  final VoidCallback onRemove;
  final bool canRemove;

  @override
  State<SkinCardEditor> createState() => _SkinCardEditorState();
}

class _SkinCardEditorState extends State<SkinCardEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late Map<String, double> _values;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.skin.name);
    _priceController = TextEditingController(
      text: _numericValue(widget.skin.values['price']),
    );
    _values = Map<String, double>.from(widget.skin.values);
  }

  @override
  void didUpdateWidget(covariant SkinCardEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.skin.id != widget.skin.id ||
        oldWidget.skin.name != widget.skin.name) {
      _nameController.text = widget.skin.name;
    }

    final nextPrice = _numericValue(widget.skin.values['price']);
    if (_priceController.text != nextPrice) {
      _priceController.text = nextPrice;
    }

    _values = Map<String, double>.from(widget.skin.values);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _emitChange({String? name, Map<String, double>? values}) {
    widget.onChanged(
      widget.skin.copyWith(
        name: name ?? _nameController.text,
        values: values ?? Map<String, double>.from(_values),
      ),
    );
  }

  void _handlePriceChanged(String rawValue) {
    final parsedValue = double.tryParse(rawValue.replaceAll(',', '.')) ?? 0;
    _values['price'] = parsedValue;
    _emitChange(values: _values);
  }

  @override
  Widget build(BuildContext context) {
    final primaryCriteria = widget.criteria.take(2).toList(growable: false);
    final remainingCriteria = widget.criteria.skip(2).toList(growable: false);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppPanel(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GlassTag(
                    label: 'SKIN ${widget.index + 1}',
                    backgroundColor: kAccentGreen,
                    borderColor: kAccentGreen,
                    textColor: Colors.black,
                  ),
                  const Spacer(),
                  NeonSecondaryButton(
                    label: '✕ Hapus',
                    height: 32,
                    filled: false,
                    onPressed: widget.canRemove ? widget.onRemove : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'NAMA / VARIAN SKIN',
                  hintText: 'Misal: Gusion Cosmic Gleam',
                ),
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  _emitChange(name: value);
                },
              ),
              const SizedBox(height: 18),
              for (final criterion in primaryCriteria) ...[
                _CriterionField(
                  criterion: criterion,
                  value: _values[criterion.id] ?? criterion.kind.defaultValue,
                  onChanged: (value) {
                    setState(() {
                      _values[criterion.id] = value;
                    });
                    _emitChange(values: _values);
                  },
                  priceController:
                      criterion.id == 'price' ? _priceController : null,
                  onPriceChanged:
                      criterion.id == 'price' ? _handlePriceChanged : null,
                  showHint: criterion.id == 'price',
                ),
                const SizedBox(height: 18),
              ],
              if (remainingCriteria.isNotEmpty) ...[
                for (final criterion in remainingCriteria) ...[
                  _CriterionField(
                    criterion: criterion,
                    value: _values[criterion.id] ?? criterion.kind.defaultValue,
                    onChanged: (value) {
                      setState(() {
                        _values[criterion.id] = value;
                      });
                      _emitChange(values: _values);
                    },
                  ),
                  const SizedBox(height: 18),
                ],
              ],
            ],
          ),
        ),
        Positioned(left: 0, top: 0, child: _CornerAccent(topLeft: true)),
        Positioned(right: 0, top: 0, child: _CornerAccent(topLeft: false)),
        Positioned(left: 0, bottom: 0, child: _CornerAccent(bottomLeft: true)),
        Positioned(
          right: 0,
          bottom: 0,
          child: _CornerAccent(bottomLeft: false),
        ),
      ],
    );
  }

  String _numericValue(double? value) {
    if (value == null || value == 0) {
      return '';
    }
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}

class _CriterionField extends StatelessWidget {
  const _CriterionField({
    required this.criterion,
    required this.value,
    required this.onChanged,
    this.priceController,
    this.onPriceChanged,
    this.showHint = false,
  });

  final CriterionDefinition criterion;
  final double value;
  final ValueChanged<double> onChanged;
  final TextEditingController? priceController;
  final ValueChanged<String>? onPriceChanged;
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    final label = criterion.label.toUpperCase();

    Widget field;
    switch (criterion.kind) {
      case CriterionKind.numeric:
        field = TextField(
          controller: priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Misal: 1089',
          ),
          onChanged: onPriceChanged,
        );
      case CriterionKind.category6:
      case CriterionKind.rating7:
      case CriterionKind.heroPreference7:
      case CriterionKind.availability2:
        field = DropdownButtonFormField<double>(
          value: value,
          dropdownColor: kSurfaceDark,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: _buildOptions(criterion)
              .map((option) {
                return DropdownMenuItem<double>(
                  value: option.value,
                  child: Text(
                    option.label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: kTextPrimary),
                  ),
                );
              })
              .toList(growable: false),
          onChanged: (selected) {
            if (selected != null) {
              onChanged(selected);
            }
          },
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        if (showHint) ...[
          const SizedBox(height: 8),
          Text(
            'Gacha: estimasi pity (Zodiac ~1500 · Collector ~4000 · Aspirants ~5000 · Legend ~9000)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: kTextMuted,
              fontSize: 9.6,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  List<_OptionEntry> _buildOptions(CriterionDefinition criterion) {
    return switch (criterion.kind) {
      CriterionKind.category6 => const [
        _OptionEntry(1, 'Common (Basic / Elite / Season)'),
        _OptionEntry(2, 'Exceptional (Special / Starlight Regular)'),
        _OptionEntry(3, 'Deluxe (Epic Shop / Epic Squad Series / Zodiac)'),
        _OptionEntry(
          4,
          'Exquisite (Epic Limited / Collector / Lucky Box / Starlight Annual)',
        ),
        _OptionEntry(
          5,
          'Grand (Collab Anime/Movie, Aspirants, Exorcists, Mistbenders)',
        ),
        _OptionEntry(6, 'Legend (Legend Magic Wheel / Legend Limited Event)'),
      ],
      CriterionKind.rating7 => const [
        _OptionEntry(1, 'Sangat Kurang'),
        _OptionEntry(2, 'Kurang'),
        _OptionEntry(3, 'Agak Kurang'),
        _OptionEntry(4, 'Standar'),
        _OptionEntry(5, 'Lumayan Bagus'),
        _OptionEntry(6, 'Bagus'),
        _OptionEntry(7, 'Sangat Bagus'),
      ],
      CriterionKind.heroPreference7 => const [
        _OptionEntry(1, 'Tidak Pernah Dipakai'),
        _OptionEntry(2, 'Sangat Jarang Dipakai'),
        _OptionEntry(3, 'Jarang Dipakai'),
        _OptionEntry(4, 'Kadang-kadang'),
        _OptionEntry(5, 'Sering Dipakai'),
        _OptionEntry(6, 'Sangat Sering Dipakai'),
        _OptionEntry(7, 'Hero Andalan Utama (Signature)'),
      ],
      CriterionKind.availability2 => const [
        _OptionEntry(1, 'Dapat Dibeli Kapan Saja di Shop'),
        _OptionEntry(2, 'Hanya Bisa Dibeli Saat Event Berlangsung (Limited)'),
      ],
      CriterionKind.numeric => const <_OptionEntry>[],
    };
  }
}

class _OptionEntry {
  const _OptionEntry(this.value, this.label);

  final double value;
  final String label;
}

class _CornerFrameLabel extends StatelessWidget {
  const _CornerFrameLabel({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      constraints: const BoxConstraints(minWidth: 64),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: kAccentGreen,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: kAccentGreen.withOpacity(0.26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'SKIN $index',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.black,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CornerAccent extends StatelessWidget {
  const _CornerAccent({this.topLeft = false, this.bottomLeft = false});

  final bool topLeft;
  final bool bottomLeft;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: topLeft
                ? const BorderSide(color: kAccentGreen)
                : BorderSide.none,
            left: bottomLeft
                ? const BorderSide(color: kAccentGreen)
                : const BorderSide(color: kAccentGreen),
            right: topLeft
                ? const BorderSide(color: kAccentGreen)
                : const BorderSide(color: kAccentGreen),
            bottom: bottomLeft
                ? const BorderSide(color: kAccentGreen)
                : const BorderSide(color: kAccentGreen),
          ),
        ),
      ),
    );
  }
}

class ResultPanel extends StatelessWidget {
  const ResultPanel({super.key, required this.results});

  final List<SkinRankingRow> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Hasil Peringkat',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: kTextPrimary,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              GlassTag(
                label: '${results.length} Skin',
                backgroundColor: const Color(0xFF0F161D),
                textColor: kTextMuted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ResultSummaryCard(row: results.first),
          const SizedBox(height: 14),
          _ResultTable(results: results),
        ],
      ),
    );
  }
}

class _ResultSummaryCard extends StatelessWidget {
  const _ResultSummaryCard({required this.row});

  final SkinRankingRow row;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 380;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.skinName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: kTextPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rekomendasi teratas berdasarkan net flow tertinggi.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: kTextMuted),
            ),
          ],
        );

        final badge = GlassTag(
          label: 'RANK #${row.rank}',
          backgroundColor: kAccentGreen,
          borderColor: kAccentGreen,
          textColor: Colors.black,
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1016),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kAccentGreen.withOpacity(0.28)),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: kAccentGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: kAccentGreen,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: titleBlock),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerLeft, child: badge),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: kAccentGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: kAccentGreen,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: titleBlock),
                    const SizedBox(width: 10),
                    badge,
                  ],
                ),
        );
      },
    );
  }
}

class _ResultTable extends StatelessWidget {
  const _ResultTable({required this.results});

  final List<SkinRankingRow> results;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = mathMax(constraints.maxWidth, 360.0);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ResultHeaderRow(minWidth: minWidth),
                const SizedBox(height: 4),
                for (final row in results) _ResultDataRow(row: row),
              ],
            ),
          ),
        );
      },
    );
  }
}

double mathMax(double left, double right) => left > right ? left : right;

class _ResultHeaderRow extends StatelessWidget {
  const _ResultHeaderRow({required this.minWidth});

  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: kTextMuted,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1016),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('#', style: cellStyle)),
          Expanded(flex: 3, child: Text('Nama Skin', style: cellStyle)),
          SizedBox(
            width: 88,
            child: Text(
              'Leaving Flow',
              style: cellStyle,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 88,
            child: Text(
              'Entering Flow',
              style: cellStyle,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 78,
            child: Text(
              'Net Flow',
              style: cellStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultDataRow extends StatelessWidget {
  const _ResultDataRow({required this.row});

  final SkinRankingRow row;

  @override
  Widget build(BuildContext context) {
    final isTop = row.recommended;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isTop ? kAccentGreen.withOpacity(0.10) : const Color(0xFF0B1016),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTop ? kAccentGreen.withOpacity(0.28) : kBorder,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${row.rank}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: kTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    row.skinName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: kTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isTop) ...[
                  const SizedBox(width: 8),
                  GlassTag(
                    label: 'REKOMENDASI',
                    backgroundColor: kAccentGreen,
                    borderColor: kAccentGreen,
                    textColor: Colors.black,
                    fontSize: 9.8,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 88,
            child: Text(
              formatFlow(row.leavingFlow),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: kTextPrimary),
            ),
          ),
          SizedBox(
            width: 88,
            child: Text(
              formatFlow(row.enteringFlow),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: kTextPrimary),
            ),
          ),
          SizedBox(
            width: 78,
            child: Text(
              formatFlow(row.netFlow),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isTop ? kAccentGreen : kTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppBrand(size: 16, footer: true),
        const SizedBox(height: 4),
        Text(
          '© 2026 Promethee Team',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: kTextMuted, fontSize: 10.5),
        ),
      ],
    );
  }
}
