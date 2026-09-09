part of 'treatment_plan_builder_sheet.dart';

class _TreatmentPlanBuilderSheetState extends ConsumerState<TreatmentPlanBuilderSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late bool _isActive;
  late final Map<ModalityType, ModalityInput> _modalityInputs;
  late final Set<ModalityType> _selectedModalities;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final plan = widget.existingPlan;
    _nameController = TextEditingController(text: plan?.planName ?? AppStrings.defaultPlanName);
    _notesController = TextEditingController(text: plan?.notes ?? '');
    _isActive = plan?.isActive ?? true;
    _modalityInputs = {for (final t in ModalityType.values) t: ModalityInput(modalityType: t)};
    _selectedModalities = {};

    if (plan != null) {
      for (final pm in plan.modalities) {
        _selectedModalities.add(pm.modalityType);
        _modalityInputs[pm.modalityType] = ModalityInput(
          modalityType: pm.modalityType,
          notes: pm.notes,
          regions: pm.regions
              .map(
                (r) => RegionInput(
                  targetRegion: r.targetRegion,
                  laterality: r.laterality,
                  timeMinutes: r.timeMinutes,
                ),
              )
              .toList(),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = await ref.read(currentUserProvider.future);
    if (_isSubmitting ||
        user?.isActive != true ||
        user?.isSeniorDoctor != true ||
        _formKey.currentState?.validate() != true) {
      return;
    }
    setState(() => _isSubmitting = true);
    final selectedList = _selectedModalities.map((type) => _modalityInputs[type]!).toList();

    final result = await ref
        .read(treatmentPlanControllerProvider.notifier)
        .upsertPlan(
          programId: widget.programId,
          patientId: widget.patientId,
          planId: widget.existingPlan?.id,
          planName: _nameController.text.trim(),
          isActive: _isActive,
          notes: _notesController.text.trim(),
          modalities: selectedList,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (plan) {
        AppSnackbar.show(
          context,
          message: AppStrings.treatmentPlanSaved,
          variant: AppSnackbarVariant.success,
        );
        Navigator.of(context).pop(plan);
      },
      failure: (e) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(e.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
  }

  void _handleToggle(ModalityType type, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedModalities.add(type);
        final current = _modalityInputs[type] ?? ModalityInput(modalityType: type);
        if (type.hasRegionSubSelections && current.regions.isEmpty) {
          final initial = _resolveSmartRegion(type);
          if (initial != null) {
            final isBilateral = ModalityTargetRegion.isRegionBilateral(type, initial);
            final target = initial == 'Paraspinal' ? 'Paraspinal (Cervical)' : initial;
            _modalityInputs[type] = current.copyWith(
              regions: [
                RegionInput(
                  targetRegion: target,
                  laterality: isBilateral ? Laterality.both : null,
                  timeMinutes: 15,
                ),
              ],
            );
          }
        }
      } else {
        _selectedModalities.remove(type);
      }
    });
  }

  String? _resolveSmartRegion(ModalityType type) {
    final available = ModalityTargetRegion.regionsFor(type);
    if (available.isEmpty) return null;
    for (final bodyRegion in widget.affectedRegions) {
      final name = bodyRegion.displayName.toLowerCase();
      final match = available
          .where((r) => r.name.toLowerCase().contains(name) || name.contains(r.name.toLowerCase()))
          .firstOrNull;
      if (match != null) return match.name;
    }
    return available.first.name;
  }

  @override
  Widget build(BuildContext context) => ClinicalEditorFrame(
    isSaving: _isSubmitting,
    onSave: _submit,
    child: Form(
      key: _formKey,
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
        children: [
          TreatmentPlanHeaderInputs(
            nameController: _nameController,
            notesController: _notesController,
            isActive: _isActive,
            onActiveChanged: (value) => setState(() => _isActive = value),
          ),
          const SizedBox(height: AppSizes.p16),
          Text(AppStrings.selectModalities, style: AppTextStyles.bodyBold),
          const SizedBox(height: AppSizes.p8),
          ModalityChipSelector(
            selectedModalities: _selectedModalities,
            onToggle: (type) => _handleToggle(type, !_selectedModalities.contains(type)),
          ),
          const SizedBox(height: AppSizes.p12),
          if (_selectedModalities.isEmpty) const RecordMessage(message: AppStrings.noModalitiesSelected),
          for (final type in ModalityType.values.where(_selectedModalities.contains))
            ModalityConfigCard(
              key: ValueKey(type),
              modalityType: type,
              isSelected: true,
              modalityInput: _modalityInputs[type]!,
              onToggle: (selected) => _handleToggle(type, selected),
              onRemove: () => _handleToggle(type, false),
              onModalityChanged: (input) => setState(() => _modalityInputs[type] = input),
            ),
          const SizedBox(height: AppSizes.p16),
        ],
      ),
    ),
  );
}
