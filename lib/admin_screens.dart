import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_controller.dart';
import 'shared_widgets.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key, required this.nextRoute});

  final String nextRoute;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _usernameController = TextEditingController(
    text: 'admin',
  );
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberSession = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final controller = AppController.of(context);
    final success = await controller.loginAdmin(
      _usernameController.text,
      _passwordController.text,
      rememberSession: _rememberSession,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!success) {
      _showMessage('Username atau password admin salah.');
      return;
    }

    Navigator.of(context).pushReplacementNamed(widget.nextRoute);
  }

  @override
  Widget build(BuildContext context) {
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
                    _AdminTopBar(
                      leadingAction: const AppBrand(size: 21),
                      trailingActions: [
                        GlassActionButton(
                          label: '← HALAMAN UTAMA',
                          onTap: () => Navigator.of(context).pushNamed('/'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'SKINDECIDE - ADMIN',
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
                      'Login Admin',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: kTextPrimary,
                            letterSpacing: 0.5,
                            fontSize: 26,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Masuk untuk mengatur kriteria rekomendasi dan reset password admin.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: kTextPrimary.withValues(alpha: 0.9),
                        height: 1.5,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppPanel(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'USERNAME ADMIN',
                              hintText: 'admin',
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'PASSWORD',
                              hintText: 'Password admin',
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 10),
                          Theme(
                            data: Theme.of(context).copyWith(
                              checkboxTheme: Theme.of(context).checkboxTheme
                                  .copyWith(
                                    visualDensity: VisualDensity.compact,
                                  ),
                            ),
                            child: CheckboxListTile(
                              value: _rememberSession,
                              onChanged: (value) {
                                setState(() {
                                  _rememberSession = value ?? true;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(
                                'Ingat sesi admin',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: kTextPrimary),
                              ),
                              dense: true,
                            ),
                          ),
                          const SizedBox(height: 18),
                          NeonPrimaryButton(
                            label: _isSubmitting
                                ? 'Memproses...'
                                : 'LOGIN ADMIN',
                            expand: true,
                            onPressed: _isSubmitting ? null : _submit,
                          ),
                        ],
                      ),
                    ),
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

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final controller = AppController.of(context);
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kSurfaceDark,
          title: const Text('Reset kriteria?'),
          content: const Text(
            'Semua perubahan kriteria akan dikembalikan ke nilai awal sistem.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      controller.resetCriteria();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kriteria berhasil dikembalikan ke nilai awal.'),
        ),
      );
    }
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
                    _AdminTopBar(
                      leadingAction: const AppBrand(size: 21),
                      trailingActions: [
                        GlassActionButton(
                          label: '← UTAMA',
                          onTap: () => Navigator.of(context).pushNamed('/'),
                        ),
                        GlassActionButton(
                          label: 'LOGOUT',
                          onTap: () async {
                            await controller.logoutAdmin();
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(
                              context,
                            ).pushNamedAndRemoveUntil('/', (route) => false);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        GlassActionButton(
                          label: 'RESET PASSWORD',
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed('/admin/password'),
                        ),
                        GlassActionButton(
                          label: 'CUSTOM BACKGROUND',
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed('/custom-background'),
                        ),
                        GlassTag(
                          label: 'Admin: ${controller.adminDisplayName}',
                          fontSize: 9.5,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'SKINDECIDE - KONFIGURASI SISTEM',
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
                      'Pengaturan Kriteria',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: kTextPrimary,
                            letterSpacing: 0.5,
                            fontSize: 26,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Sesuaikan tipe kriteria, bobot kepentingan, serta tipe fungsi preferensi PROMETHEE beserta batas threshold (p, q, s).',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: kTextPrimary.withValues(alpha: 0.9),
                        height: 1.5,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppPanel(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Kontrol Admin',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: kTextPrimary, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gunakan reset untuk mengembalikan daftar kriteria ke nilai awal sistem.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: kTextMuted, height: 1.4),
                          ),
                          const SizedBox(height: 18),
                          NeonSecondaryButton(
                            label: 'RESET KRITERIA SEMULA',
                            icon: Icons.restart_alt_rounded,
                            expand: true,
                            onPressed: () => _confirmReset(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Daftar Kriteria Aktif',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: kTextPrimary,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final criterion in controller.criteria) ...[
                      CriterionCardEditor(
                        key: ValueKey(criterion.id),
                        criterion: criterion,
                        onSave: controller.updateCriterion,
                        onDelete: () =>
                            controller.removeCriterion(criterion.id),
                      ),
                      const SizedBox(height: 18),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Tambah Kriteria Baru',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: kTextPrimary,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AddCriterionForm(onAdd: controller.addCriterion),
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

class CriterionCardEditor extends StatefulWidget {
  const CriterionCardEditor({
    super.key,
    required this.criterion,
    required this.onSave,
    required this.onDelete,
  });

  final CriterionDefinition criterion;
  final ValueChanged<CriterionDefinition> onSave;
  final VoidCallback onDelete;

  @override
  State<CriterionCardEditor> createState() => _CriterionCardEditorState();
}

class _CriterionCardEditorState extends State<CriterionCardEditor> {
  late final TextEditingController _labelController;
  late final TextEditingController _weightController;
  late CriterionOptimization _optimization;
  late PreferenceFunction _function;
  late bool _isCore;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.criterion.label);
    _weightController = TextEditingController(
      text: formatWeight(widget.criterion.weight),
    );
    _optimization = widget.criterion.optimization;
    _function = widget.criterion.function;
    _isCore = widget.criterion.isCore;
  }

  @override
  void didUpdateWidget(covariant CriterionCardEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.criterion.id != widget.criterion.id ||
        oldWidget.criterion.label != widget.criterion.label) {
      _labelController.text = widget.criterion.label;
    }
    final weightText = formatWeight(widget.criterion.weight);
    if (_weightController.text != weightText) {
      _weightController.text = weightText;
    }
    _optimization = widget.criterion.optimization;
    _function = widget.criterion.function;
    _isCore = widget.criterion.isCore;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _save() {
    final weight =
        double.tryParse(_weightController.text.replaceAll(',', '.')) ??
        widget.criterion.weight;
    widget.onSave(
      widget.criterion.copyWith(
        label: _labelController.text.trim().isEmpty
            ? widget.criterion.label
            : _labelController.text.trim(),
        optimization: _optimization,
        weight: weight <= 0 ? 1 : weight,
        function: _function,
        isCore: _isCore,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.criterion.label} berhasil disimpan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.criterion.label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: kTextPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GlassTag(
                      label: _optimization.displayLabel.toUpperCase(),
                      backgroundColor:
                          _optimization == CriterionOptimization.maximize
                          ? const Color(0xFF14210E)
                          : const Color(0xFF231B11),
                      borderColor:
                          _optimization == CriterionOptimization.maximize
                          ? kAccentGreen.withValues(alpha: 0.35)
                          : Colors.orange.withValues(alpha: 0.35),
                      textColor: _optimization == CriterionOptimization.maximize
                          ? kAccentGreen
                          : Colors.orangeAccent,
                      fontSize: 9.5,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              NeonSecondaryButton(
                label: '✕',
                height: 36,
                filled: false,
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(labelText: 'NAMA KRITERIA'),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<CriterionOptimization>(
            initialValue: _optimization,
            dropdownColor: kSurfaceDark,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'TIPE OPTIMASI'),
            items: CriterionOptimization.values
                .map(
                  (value) => DropdownMenuItem<CriterionOptimization>(
                    value: value,
                    child: Text(
                      value == CriterionOptimization.maximize
                          ? 'Maximize'
                          : 'Minimize',
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _optimization = value;
              });
            },
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(labelText: 'BOBOT (WEIGHT)'),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<PreferenceFunction>(
            initialValue: _function,
            dropdownColor: kSurfaceDark,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'FUNGSI PREFERENSI'),
            items: PreferenceFunction.values
                .map(
                  (value) => DropdownMenuItem<PreferenceFunction>(
                    value: value,
                    child: Text(value.displayLabel),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _function = value;
              });
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: NeonPrimaryButton(label: 'SIMPAN', onPressed: _save),
              ),
              if (_isCore) ...[
                const SizedBox(width: 12),
                Text(
                  'Kriteria inti sistem',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: kTextMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class AddCriterionForm extends StatefulWidget {
  const AddCriterionForm({super.key, required this.onAdd});

  final ValueChanged<CriterionDefinition> onAdd;

  @override
  State<AddCriterionForm> createState() => _AddCriterionFormState();
}

class _AddCriterionFormState extends State<AddCriterionForm> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _weightController = TextEditingController(
    text: '1',
  );
  CriterionOptimization _optimization = CriterionOptimization.maximize;
  PreferenceFunction _function = PreferenceFunction.usual;

  @override
  void dispose() {
    _labelController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _addCriterion() {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama kriteria baru belum diisi.')),
      );
      return;
    }

    final weight =
        double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 1;
    widget.onAdd(
      CriterionDefinition(
        id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
        label: label,
        kind: CriterionKind.rating7,
        optimization: _optimization,
        weight: weight <= 0 ? 1 : weight,
        function: _function,
        isCore: false,
      ),
    );

    _labelController.clear();
    _weightController.text = '1';
    setState(() {
      _optimization = CriterionOptimization.maximize;
      _function = PreferenceFunction.usual;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Kriteria baru ditambahkan.')));
  }

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final fieldWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: TextField(
                      controller: _labelController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kriteria Baru',
                        hintText: 'Misal: Efek Suara Skin',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<CriterionOptimization>(
                      initialValue: _optimization,
                      isExpanded: true,
                      dropdownColor: kSurfaceDark,
                      decoration: const InputDecoration(
                        labelText: 'Tipe Optimasi',
                      ),
                      items: CriterionOptimization.values
                          .map(
                            (value) => DropdownMenuItem<CriterionOptimization>(
                              value: value,
                              child: Text(
                                value == CriterionOptimization.maximize
                                    ? 'Maximize'
                                    : 'Minimize',
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _optimization = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Bobot (Weight)',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<PreferenceFunction>(
                      initialValue: _function,
                      isExpanded: true,
                      dropdownColor: kSurfaceDark,
                      decoration: const InputDecoration(
                        labelText: 'Fungsi Preferensi',
                      ),
                      items: PreferenceFunction.values
                          .map(
                            (value) => DropdownMenuItem<PreferenceFunction>(
                              value: value,
                              child: Text(value.displayLabel),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _function = value;
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          NeonPrimaryButton(
            label: 'Tambahkan Kriteria Baru',
            icon: Icons.add_rounded,
            expand: true,
            onPressed: _addCriterion,
          ),
        ],
      ),
    );
  }
}

class CustomBackgroundScreen extends StatefulWidget {
  const CustomBackgroundScreen({super.key});

  @override
  State<CustomBackgroundScreen> createState() => _CustomBackgroundScreenState();
}

class _CustomBackgroundScreenState extends State<CustomBackgroundScreen> {
  bool _loading = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickBackground() async {
    final controller = AppController.of(context);

    setState(() {
      _loading = true;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      _showMessage('Gagal membaca file gambar yang dipilih.');
      return;
    }

    await controller.setBackgroundImage(file.name, bytes);
    _showMessage('Background berhasil diperbarui.');
  }

  Future<void> _resetBackground() async {
    await AppController.of(context).resetBackground();
    if (!mounted) {
      return;
    }
    _showMessage('Background kembali ke default.');
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
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AdminTopBar(
                      leadingAction: const AppBrand(size: 22),
                      trailingActions: [
                        GlassActionButton(
                          label: '← HALAMAN PENGATURAN',
                          onTap: () =>
                              Navigator.of(context).pushNamed('/pengaturan'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    AppPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'SKINDECIDE - SETTING BACKGROUND',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: kAccentGreen,
                                  letterSpacing: 1.3,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Custom Background',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: kTextPrimary, fontSize: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sesuaikan background global website SkinDecide. Gambar yang disimpan admin akan tampil untuk semua pengunjung.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white, height: 1.45),
                          ),
                          const SizedBox(height: 22),
                          AppPanel(
                            backgroundColor: const Color(0xFF0B1016),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'PREVIEW & SETTING',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: kTextPrimary,
                                        fontSize: 17,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Preview Gambar Saat Ini :',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: kTextMuted),
                                ),
                                const SizedBox(height: 12),
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image(
                                          image: controller
                                              .backgroundImageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black.withValues(
                                                  alpha: 0.25,
                                                ),
                                                Colors.black.withValues(
                                                  alpha: 0.65,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.image_rounded,
                                                color: kAccentGreen,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                controller.backgroundName ??
                                                    'Background default aktif',
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: kTextPrimary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final narrow = constraints.maxWidth < 460;
                                    final pickButton = NeonSecondaryButton(
                                      label: _loading
                                          ? 'Memuat...'
                                          : 'Pilih Gambar Lokal',
                                      icon: Icons.upload_file_rounded,
                                      expand: true,
                                      onPressed: _loading
                                          ? null
                                          : _pickBackground,
                                    );
                                    final resetButton = NeonSecondaryButton(
                                      label: 'Reset Default',
                                      icon: Icons.restart_alt_rounded,
                                      expand: true,
                                      onPressed: _loading
                                          ? null
                                          : _resetBackground,
                                    );

                                    if (narrow) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          pickButton,
                                          const SizedBox(height: 10),
                                          resetButton,
                                        ],
                                      );
                                    }

                                    return Row(
                                      children: [
                                        Expanded(child: pickButton),
                                        const SizedBox(width: 12),
                                        Expanded(child: resetButton),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    final currentPassword = _currentController.text;
    final newPassword = _newController.text;
    final confirmPassword = _confirmController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Password baru belum diisi.');
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage('Konfirmasi password baru tidak sama.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final success = await AppController.of(
      context,
    ).updateAdminPassword(currentPassword, newPassword);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (!success) {
      _showMessage('Password saat ini tidak sesuai.');
      return;
    }

    _currentController.clear();
    _newController.clear();
    _confirmController.clear();
    _showMessage('Password admin berhasil diperbarui.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AdminTopBar(
                      leadingAction: const AppBrand(size: 22),
                      trailingActions: [
                        GlassActionButton(
                          label: '← Pengaturan Kriteria',
                          onTap: () =>
                              Navigator.of(context).pushNamed('/pengaturan'),
                        ),
                        GlassActionButton(
                          label: 'Logout',
                          onTap: () async {
                            await AppController.of(context).logoutAdmin();
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(
                              context,
                            ).pushNamedAndRemoveUntil('/', (route) => false);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    AppPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'SkinDecide - Admin',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: kAccentGreen,
                                  letterSpacing: 1.3,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Reset Password',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: kTextPrimary, fontSize: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ubah password admin yang sedang login.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white, height: 1.45),
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: _currentController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password Saat Ini',
                            ),
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 520;
                              final newPasswordField = TextField(
                                controller: _newController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password Baru',
                                ),
                              );
                              final confirmPasswordField = TextField(
                                controller: _confirmController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Konfirmasi Password Baru',
                                ),
                              );

                              if (isNarrow) {
                                return Column(
                                  children: [
                                    newPasswordField,
                                    const SizedBox(height: 14),
                                    confirmPasswordField,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: newPasswordField),
                                  const SizedBox(width: 12),
                                  Expanded(child: confirmPasswordField),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          NeonPrimaryButton(
                            label: _isSaving
                                ? 'Menyimpan...'
                                : 'Simpan Password Baru',
                            expand: true,
                            onPressed: _isSaving ? null : _save,
                          ),
                        ],
                      ),
                    ),
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

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.leadingAction,
    required this.trailingActions,
  });

  final Widget leadingAction;
  final List<Widget> trailingActions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 620;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerLeft, child: leadingAction),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: trailingActions,
              ),
            ],
          );
        }

        return Row(
          children: [
            leadingAction,
            const Spacer(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: trailingActions,
            ),
          ],
        );
      },
    );
  }
}
