import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/medicine_model.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../services/api_service.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? existing;
  const AddMedicineScreen({super.key, this.existing});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _dosageAmountController;
  late TextEditingController _instructionsController;
  late TextEditingController _stockController;

  String _dosageUnit = 'mg';
  static const List<String> _dosageUnits = [
    'mg', 'g', 'mcg', 'ml', 'IU', 'units', '%', 'other',
  ];

  MedicineForm _selectedForm = MedicineForm.tablet;
  String _frequency = 'Once a day';
  List<TimeOfDay> _times = [const TimeOfDay(hour: 9, minute: 0)];
  Color _selectedColor = AppColors.primary;

  final _frequencies = const [
    'Once a day', 'Twice a day', 'Thrice a day', 'Weekly', 'As needed',
  ];
  final _colors = const [
    AppColors.primary,
    AppColors.secondary,
    AppColors.warning,
    AppColors.info,
    AppColors.danger,
  ];

  List<Map<String, dynamic>> _suggestions = [];
  bool _loadingSuggestions = false;
  bool _loadingInfo = false;
  Map<String, dynamic>? _medicineInfo;
  Timer? _debounce;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _nameFocus = FocusNode();
  OverlayEntry? _overlayEntry;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    final existingDosage = e?.dosage ?? '';
    final dosageParts = _splitDosage(existingDosage);
    _dosageAmountController = TextEditingController(text: dosageParts.$1);
    _dosageUnit = dosageParts.$2;
    _instructionsController = TextEditingController(text: e?.instructions ?? '');
    _stockController = TextEditingController(text: (e?.stockCount ?? 30).toString());
    if (e != null) {
      _selectedForm = e.form;
      _frequency = e.frequency;
      _times = List.from(e.times);
      _selectedColor = e.color;
    }
    _nameController.addListener(_onNameChanged);
    // Do not auto-dismiss suggestions on focus loss — that cancels ListTile taps.
  }

  (String, String) _splitDosage(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return ('', 'mg');
    final match = RegExp(r'^([\d./]+)\s*(.*)$').firstMatch(trimmed);
    if (match == null) return (trimmed, 'mg');
    final amount = match.group(1) ?? '';
    var unit = (match.group(2) ?? '').trim();
    if (unit.isEmpty) unit = 'mg';
    final known = _dosageUnits.firstWhere(
      (u) => u.toLowerCase() == unit.toLowerCase(),
      orElse: () => 'other',
    );
    return (amount, known == 'other' && unit.isNotEmpty ? unit : known);
  }

  String _combinedDosage() {
    final amount = _dosageAmountController.text.trim();
    final unit = _dosageUnit == 'other' ? '' : _dosageUnit;
    if (amount.isEmpty) return '';
    return unit.isEmpty ? amount : '$amount $unit';
  }

  void _onNameChanged() {
    _debounce?.cancel();
    final q = _nameController.text.trim();
    if (q.length < 2) {
      setState(() {
        _suggestions = [];
        _medicineInfo = null;
      });
      _removeOverlay();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), () {
      _fetchSuggestions(q);
    });
  }

  Future<void> _fetchSuggestions(String q) async {
    setState(() => _loadingSuggestions = true);
    try {
      final result = await _api.suggestMedicines(q);
      if (!mounted) return;
      if (result['success'] == true) {
        final list = (result['data']['suggestions'] as List?) ?? [];
        _suggestions = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        setState(() {});
        // Inline list under the search field (more reliable than Overlay taps)
      }
    } catch (_) {
      // silent — user can still type freely
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  void _showOverlay() {
    _removeOverlay();
    if (_suggestions.isEmpty || !_nameFocus.hasFocus) return;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width - 40,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = _suggestions[index];
                    final name = s['name']?.toString() ?? '';
                    final dosage = s['dosage']?.toString() ?? '';
                    final form = s['form']?.toString() ?? '';
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.medication_outlined, color: AppColors.primary),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('$dosage · $form'),
                      onTap: () => _selectSuggestion(s),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _selectSuggestion(Map<String, dynamic> s) async {
    final name = (s['name']?.toString() ?? '').trim();
    if (name.isEmpty) return;

    // Hide list immediately and fill name so the user sees feedback
    setState(() {
      _suggestions = [];
      _loadingInfo = true;
      _medicineInfo = null;
    });
    _removeOverlay();

    _nameController.removeListener(_onNameChanged);
    _nameController.text = name;
    _nameController.addListener(_onNameChanged);

    // Prefill what we already know from the suggestion row
    final dosage = s['dosage']?.toString() ?? '';
    if (dosage.isNotEmpty) {
      final parts = _splitDosage(dosage);
      _dosageAmountController.text = parts.$1;
      _dosageUnit = parts.$2;
    }
    final freq = s['frequency']?.toString();
    if (freq != null && _frequencies.contains(freq)) {
      _frequency = freq;
    }
    final formName = s['form']?.toString().toLowerCase();
    if (formName != null) {
      for (final form in MedicineForm.values) {
        if (form.name == formName) {
          _selectedForm = form;
          break;
        }
      }
    }
    setState(() {});

    // Full profile from API (OpenFDA / local)
    await _loadMedicineInfo(name);
  }

  Future<void> _onNameSubmitted(String value) async {
    final name = value.trim();
    if (name.isEmpty) return;
    _removeOverlay();
    await _loadMedicineInfo(name);
  }

  Future<void> _loadMedicineInfo(String name) async {
    setState(() {
      _loadingInfo = true;
      _medicineInfo = null;
    });
    try {
      final result = await _api.getMedicineInfo(name);
      if (!mounted) return;
      if (result['success'] == true) {
        final info = Map<String, dynamic>.from(result['data']['info'] as Map);
        _applyInfoToForm(info);
        setState(() => _medicineInfo = info);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingInfo = false);
    }
  }

  void _applyInfoToForm(Map<String, dynamic> info) {
    if (info['name'] != null && info['name'].toString().isNotEmpty) {
      _nameController.removeListener(_onNameChanged);
      _nameController.text = info['name'].toString();
      _nameController.addListener(_onNameChanged);
    }
    final d = info['dosage']?.toString() ?? '';
    if (d.isNotEmpty) {
      final parts = _splitDosage(d);
      _dosageAmountController.text = parts.$1;
      _dosageUnit = parts.$2;
    }
    if (info['frequency'] != null) {
      final f = info['frequency'].toString();
      if (_frequencies.contains(f)) _frequency = f;
    }
    if (info['form'] != null) {
      final formName = info['form'].toString().toLowerCase();
      for (final form in MedicineForm.values) {
        if (form.name == formName) {
          _selectedForm = form;
          break;
        }
      }
    }
    if (info['instructions'] != null) {
      _instructionsController.text = info['instructions'].toString();
    }
    if (info['times'] is List && (info['times'] as List).isNotEmpty) {
      try {
        _times = (info['times'] as List).map((t) {
          final m = Map<String, dynamic>.from(t as Map);
          return TimeOfDay(hour: m['hour'] ?? 9, minute: m['minute'] ?? 0);
        }).toList();
      } catch (_) {}
    }
    setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _nameFocus.dispose();
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _dosageAmountController.dispose();
    _instructionsController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(context: context, initialTime: _times[index]);
    if (picked != null) setState(() => _times[index] = picked);
  }

  void _addTimeSlot() {
    setState(() => _times.add(const TimeOfDay(hour: 12, minute: 0)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<MedicineProvider>();
    final medicine = Medicine(
      id: widget.existing?.id ?? 'm_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      dosage: _combinedDosage(),
      form: _selectedForm,
      frequency: _frequency,
      times: _times,
      startDate: widget.existing?.startDate ?? DateTime.now(),
      instructions: _instructionsController.text.trim(),
      color: _selectedColor,
      stockCount: int.tryParse(_stockController.text) ?? 30,
    );
    final ok = _isEditing
        ? await provider.updateMedicine(medicine)
        : await provider.addMedicine(medicine);
    if (!mounted) return;
    if (ok) {
      await context.read<ReminderProvider>().loadTodayDoses();
      await context.read<ReminderProvider>().loadUpcomingDoses();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${medicine.name} ${_isEditing ? 'updated' : 'added'} successfully',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to save medicine')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medicine' : 'Add Medicine'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Medicine Name',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              CompositedTransformTarget(
                link: _layerLink,
                child: TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  textInputAction: TextInputAction.search,
                  onFieldSubmitted: _onNameSubmitted,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter medicine name' : null,
                  decoration: InputDecoration(
                    hintText: 'Start typing e.g. Metformin, Dolo…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _loadingSuggestions
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Get AI info',
                            icon: const Icon(Icons.auto_awesome),
                            onPressed: () {
                              final n = _nameController.text.trim();
                              if (n.isNotEmpty) _loadMedicineInfo(n);
                            },
                          ),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.6,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(14),
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final s = _suggestions[index];
                        final name = s['name']?.toString() ?? '';
                        final dosage = s['dosage']?.toString() ?? '';
                        final form = s['form']?.toString() ?? '';
                        final source = s['source']?.toString() ?? '';
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.medication_outlined, color: AppColors.primary),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            [
                              if (dosage.isNotEmpty) dosage,
                              if (form.isNotEmpty) form,
                              if (source.isNotEmpty) source,
                            ].join(' · '),
                          ),
                          onTap: () => _selectSuggestion(s),
                        );
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              const Text(
                'Suggestions appear as you type. Tap one (or press Enter / ✨) for uses & side effects.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              if (_loadingInfo) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_medicineInfo != null) ...[
                const SizedBox(height: 16),
                _infoCard(_medicineInfo!),
              ],
              const SizedBox(height: 18),
              const Text('Form', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: MedicineForm.values.map((f) {
                  final selected = _selectedForm == f;
                  return ChoiceChip(
                    label: Text(f.label),
                    avatar: Icon(
                      f.icon,
                      size: 16,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondaryLight,
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedForm = f),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    backgroundColor: Colors.transparent,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary
                            : AppColors.borderLight,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              const Text('Dosage', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _dosageAmountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter amount' : null,
                      decoration: InputDecoration(
                        hintText: 'e.g. 500',
                        prefixIcon: const Icon(Icons.science_outlined),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _dosageUnits.contains(_dosageUnit)
                          ? _dosageUnit
                          : 'mg',
                      isExpanded: true,
                      items: _dosageUnits
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _dosageUnit = v ?? 'mg'),
                      decoration: InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Frequency',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _frequency,
                items: _frequencies
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _frequency = v ?? _frequency),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.repeat_rounded),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reminder Times',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: _addTimeSlot,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add time'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_times.length, (index) {
                  return InkWell(
                    onTap: () => _pickTime(index),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _times[index].format(context),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (_times.length > 1) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => _times.removeAt(index)),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              CustomTextField(
                label: 'Instructions (optional)',
                controller: _instructionsController,
                hint: 'e.g. Take after food',
                prefixIcon: Icons.info_outline_rounded,
              ),
              const SizedBox(height: 18),
              CustomTextField(
                label: 'Current Stock (units)',
                controller: _stockController,
                hint: 'e.g. 30',
                prefixIcon: Icons.inventory_2_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 18),
              const Text(
                'Color Tag',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                children: _colors.map((c) {
                  final selected = _selectedColor == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: selected ? 40 : 34,
                        width: selected ? 40 : 34,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: Colors.black26, width: 2)
                              : null,
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              PrimaryButton(
                label: _isEditing ? 'Save Changes' : 'Add Medicine',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(Map<String, dynamic> info) {
    final found = info['found'] == true;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                found ? Icons.auto_awesome : Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  found
                      ? 'AI insights: ${info['name']}'
                      : 'No full profile — enter details carefully',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('Uses', info['uses']?.toString() ?? ''),
          _infoRow('Side effects', info['sideEffects']?.toString() ?? ''),
          _infoRow('When to take', info['whenToTake']?.toString() ?? ''),
          if ((info['precautions']?.toString() ?? '').isNotEmpty)
            _infoRow('Precautions', info['precautions']?.toString() ?? ''),
          const SizedBox(height: 6),
          const Text(
            'Informational only — always follow your doctor or package label.',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondaryLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String body) {
    if (body.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}
