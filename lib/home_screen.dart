import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_controller.dart';
import 'shared_widgets.dart';
import 'chatbot_page.dart';

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

  Future<void> _calculate() async {
    final controller = AppController.of(context);
    final validation = controller.validateComparisonInputs();
    if (validation != null) {
      _showMessage(validation);
      return;
    }

    try {
      await controller.calculateRanking();
      if (!mounted) {
        return;
      }
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
    } on SkinRecommendationException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppController.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= kBreakpointDesktop;
    final isTablet =
        screenWidth >= kBreakpointTablet && screenWidth < kBreakpointDesktop;

    final contentMaxWidth = isDesktop ? 1100.0 : isTablet ? 720.0 : 430.0;
    final horizontalPadding = isDesktop ? 32.0 : isTablet ? 24.0 : 16.0;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00FF66),
        child: const Icon(Icons.chat_bubble, color: Color(0xFF050B14)),
        onPressed: () {
          // Navigasi langsung ke kelas halaman Chatbot tanpa lewat NamedRoute
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatbotPage()),
          );
        },
      ),
      body: AppBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              14,
              horizontalPadding,
              24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useGrid = constraints.maxWidth >= 640;

                        if (useGrid) {
                          final cardWidth = (constraints.maxWidth - 18) / 2;
                          return Wrap(
                            spacing: 18,
                            runSpacing: 18,
                            children: [
                              for (
                                var index = 0;
                                index < controller.skins.length;
                                index++
                              )
                                SizedBox(
                                  width: cardWidth,
                                  child: SkinCardEditor(
                                    key: ValueKey(controller.skins[index].id),
                                    index: index,
                                    skin: controller.skins[index],
                                    criteria: controller.criteria,
                                    onChanged: controller.updateSkin,
                                    onRemove: () => controller.removeSkin(
                                      controller.skins[index].id,
                                    ),
                                    canRemove: controller.skins.length > 2,
                                  ),
                                ),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                                onRemove: () => controller.removeSkin(
                                  controller.skins[index].id,
                                ),
                                canRemove: controller.skins.length > 2,
                              ),
                              if (index != controller.skins.length - 1)
                                const SizedBox(height: 18),
                            ],
                          ],
                        );
                      },
                    ),
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
                        final resetButton = NeonSecondaryButton(
                          label: 'Hapus Input Tersimpan',
                          icon: Icons.delete_outline_rounded,
                          expand: true,
                          onPressed: controller.resetComparisonInputs,
                        );
                        final calculateButton = NeonPrimaryButton(
                          label: controller.isCalculating
                              ? 'Menghitung...'
                              : 'Hitung Rekomendasi',
                          icon: controller.isCalculating
                              ? Icons.hourglass_top_rounded
                              : Icons.analytics_rounded,
                          expand: true,
                          onPressed: controller.isCalculating
                              ? null
                              : _calculate,
                        );

                        if (narrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              resetButton,
                              const SizedBox(height: 10),
                              calculateButton,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: resetButton),
                            const SizedBox(width: 12),
                            Expanded(child: calculateButton),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    if (controller.calculationError != null) ...[
                      const SizedBox(height: 12),
                      _CalculationErrorPanel(
                        message: controller.calculationError!,
                      ),
                    ],
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
          'SKINDECIDE - Asisten Keputusan Pembelian Skin Mobile Legends',
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
                color: kTextPrimary.withValues(alpha: 0.9),
                height: 1.5,
                fontSize: 13.5,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          '(Masukkan Skala 1-7, khusus Kategori masukkan skala 1-6, dan untuk Harga masukkan dalam jumlah Diamond)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: kTextMuted.withValues(alpha: 0.85),
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
  late final FocusNode _nameFocusNode;
  late final TextEditingController _priceController;
  late Map<String, double> _values;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.skin.name);
    _nameFocusNode = FocusNode();
    _priceController = TextEditingController(
      text: _numericValue(widget.skin.values['price']),
    );
    _values = Map<String, double>.from(widget.skin.values);
  }

  @override
  void didUpdateWidget(covariant SkinCardEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.skin.id != widget.skin.id) {
      _nameController.text = widget.skin.name;
    } else if (!_nameFocusNode.hasFocus &&
        _nameController.text != widget.skin.name) {
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
    _nameFocusNode.dispose();
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
                focusNode: _nameFocusNode,
                decoration: const InputDecoration(
                  labelText: 'NAMA / VARIAN SKIN',
                  hintText: 'Misal: Gusion Cosmic Gleam',
                ),
                textInputAction: TextInputAction.next,
                maxLength: 75,
                maxLines: 1,
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
                  priceController: criterion.id == 'price'
                      ? _priceController
                      : null,
                  onPriceChanged: criterion.id == 'price'
                      ? _handlePriceChanged
                      : null,
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
          initialValue: value,
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
          _OptionEntry(
            2,
            'Hanya Bisa Dibeli Saat Event Berlangsung (Limited)',
          ),
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

class _CalculationErrorPanel extends StatelessWidget {
  const _CalculationErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      borderColor: const Color(0xFFFF5A5F).withValues(alpha: 0.32),
      backgroundColor: const Color(0xFF1A1114),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFF8A8E),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFFFC8CB),
                    height: 1.45,
                  ),
            ),
          ),
        ],
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
            border: Border.all(color: kAccentGreen.withValues(alpha: 0.28)),
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
                            color: kAccentGreen.withValues(alpha: 0.15),
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
                        color: kAccentGreen.withValues(alpha: 0.15),
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
        final tableWidth = constraints.hasBoundedWidth
            ? mathMax(constraints.maxWidth, 360.0)
            : 360.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111820).withValues(alpha: 0.90),
                  border: Border.all(color: kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ResultHeaderRow(),
                    for (var index = 0; index < results.length; index++)
                      _ResultDataRow(
                        row: results[index],
                        isLast: index == results.length - 1,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

double mathMax(double left, double right) => left > right ? left : right;

const double _resultRankWidth = 56;
const double _resultMetricWidth = 66;
const EdgeInsets _resultHeaderPadding = EdgeInsets.symmetric(
  horizontal: 20,
  vertical: 14,
);
const EdgeInsets _resultRowPadding = EdgeInsets.symmetric(
  horizontal: 20,
  vertical: 16,
);

class _ResultHeaderRow extends StatelessWidget {
  const _ResultHeaderRow();

  @override
  Widget build(BuildContext context) {
    final cellStyle = GoogleFonts.jetBrainsMono(
      fontSize: 9.4,
      fontWeight: FontWeight.w500,
      color: kTextMuted,
      letterSpacing: 0.9,
      height: 1,
    );

    return Container(
      padding: _resultHeaderPadding,
      decoration: const BoxDecoration(
        color: Color(0xFF82CD27),
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          SizedBox(width: _resultRankWidth, child: Text('#', style: cellStyle)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Nama Skin',
              style: cellStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _ResultHeaderMetricCell(label: 'Leaving Flow', style: cellStyle),
          _ResultHeaderMetricCell(label: 'Entering Flow', style: cellStyle),
          _ResultHeaderMetricCell(
            label: 'Net Flow',
            style: cellStyle.copyWith(color: kAccentGreen),
            align: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

class _ResultDataRow extends StatelessWidget {
  const _ResultDataRow({required this.row, required this.isLast});

  final SkinRankingRow row;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isTop = row.recommended;
    final rankStyle = isTop
        ? GoogleFonts.orbitron(
            fontSize: 11.2,
            fontWeight: FontWeight.w700,
            color: kAccentGreen,
            letterSpacing: 0.3,
            height: 1,
          )
        : GoogleFonts.jetBrainsMono(
            fontSize: 10.8,
            fontWeight: FontWeight.w400,
            color: kTextMuted,
            letterSpacing: 0.2,
            height: 1,
          );

    final nameStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isTop ? kAccentGreen : kTextPrimary,
          fontWeight: isTop ? FontWeight.w700 : FontWeight.w600,
          height: 1.25,
        );

    return Container(
      padding: _resultRowPadding,
      decoration: BoxDecoration(
        color: isTop ? const Color(0x1482CD27) : const Color(0xFF0B1016),
        border: Border(
          bottom: BorderSide(color: isLast ? Colors.transparent : kBorder),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _resultRankWidth,
            child: Text(
              '${row.rank}',
              style: rankStyle,
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  row.skinName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: nameStyle,
                ),
                if (isTop) const _ResultTrophyBadge(),
              ],
            ),
          ),
          _ResultMetricCell(
            value: formatFlow(row.leavingFlow),
            color: kTextMuted,
          ),
          _ResultMetricCell(
            value: formatFlow(row.enteringFlow),
            color: kTextMuted,
          ),
          _ResultMetricCell(
            value: formatFlow(row.netFlow),
            color: row.netFlow > 0
                ? const Color(0xFF4ADE80)
                : row.netFlow < 0
                    ? const Color(0xFFF87171)
                    : kTextPrimary,
            align: TextAlign.right,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}

class _ResultHeaderMetricCell extends StatelessWidget {
  const _ResultHeaderMetricCell({
    required this.label,
    required this.style,
    this.align = TextAlign.center,
  });

  final String label;
  final TextStyle style;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final alignment = align == TextAlign.right
        ? Alignment.centerRight
        : Alignment.center;

    return SizedBox(
      width: _resultMetricWidth,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(
          label,
          style: style,
          textAlign: align,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }
}

class _ResultMetricCell extends StatelessWidget {
  const _ResultMetricCell({
    required this.value,
    required this.color,
    this.align = TextAlign.center,
    this.fontWeight = FontWeight.w600,
  });

  final String value;
  final Color color;
  final TextAlign align;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final alignment = align == TextAlign.right
        ? Alignment.centerRight
        : Alignment.center;

    return SizedBox(
      width: _resultMetricWidth,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(
          value,
          textAlign: align,
          maxLines: 1,
          softWrap: false,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: fontWeight,
            color: color,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _ResultTrophyBadge extends StatelessWidget {
  const _ResultTrophyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x26F0B429), Color(0x0DF0B429)],
        ),
        border: Border.all(color: const Color(0x40F0B429)),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14F0B429),
            blurRadius: 10,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Text(
        'REKOMENDASI',
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 8.9,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFF0B429),
          letterSpacing: 0.9,
          height: 1,
        ),
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