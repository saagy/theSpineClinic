part of 'appointment_filter_sheet.dart';

class _AppointmentFilterSheetState extends ConsumerState<AppointmentFilterSheet> {
  _FilterSheetPage _page = _FilterSheetPage.main;
  late DateTime? _dateFrom = widget.initialDateFrom;
  late DateTime? _dateTo = widget.initialDateTo;
  late String? _doctorId = widget.initialDoctorId;
  late ClinicLocation? _clinic = widget.initialClinic;
  late AppointmentStatus? _status = widget.initialStatus;
  late AppointmentType? _type = widget.initialType;
  late AppointmentSortOption _sort = widget.initialSort;

  void _reset() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
      _doctorId = null;
      _clinic = null;
      _status = null;
      _type = null;
      _sort = AppointmentSortOption.dateDesc;
      widget.onResetAdditional?.call();
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      AppointmentFilterResult(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        doctorId: _doctorId,
        clinic: _clinic,
        status: _status,
        type: _type,
        sortOption: _sort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doctors = widget.canFilterDoctor
        ? (ref.watch(allDoctorsForFilterProvider).value ?? const <Staff>[])
        : const <Staff>[];

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.r16)),
        border: Border.all(color: cs.outlineVariant, width: AppSizes.borderWidth),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _page == _FilterSheetPage.doctorPicker
              ? AppointmentFilterDoctorView(
                  selectedDoctorId: _doctorId,
                  doctors: doctors,
                  onDoctorSelected: (id) => setState(() {
                    _doctorId = id;
                    _page = _FilterSheetPage.main;
                  }),
                  onBack: () => setState(() => _page = _FilterSheetPage.main),
                )
              : AppointmentFilterMainView(
                  appointmentFiltersBuilder: widget.appointmentFiltersBuilder,
                  showAppointmentFilters: widget.showAppointmentFilters,
                  selectedDateFrom: _dateFrom,
                  selectedDateTo: _dateTo,
                  selectedDoctorId: _doctorId,
                  selectedClinic: _clinic,
                  selectedStatus: _status,
                  selectedType: _type,
                  selectedSort: _sort,
                  canFilterDoctor: widget.canFilterDoctor,
                  canFilterClinic: widget.canFilterClinic,
                  doctors: doctors,
                  onDateRangeChanged: (from, to) => setState(() {
                    _dateFrom = from;
                    _dateTo = to;
                  }),
                  onOpenDoctorPicker: () => setState(() => _page = _FilterSheetPage.doctorPicker),
                  onClinicChanged: (c) => setState(() => _clinic = c),
                  onStatusChanged: (s) => setState(() => _status = s),
                  onTypeChanged: (t) => setState(() => _type = t),
                  onSortChanged: (s) => setState(() => _sort = s),
                  onReset: _reset,
                  onApply: _apply,
                ),
        ),
      ),
    );
  }
}
