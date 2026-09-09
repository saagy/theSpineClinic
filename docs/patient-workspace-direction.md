# Patient workspace — September 2026

The first Flutter pilot was rejected. The [correction audit](patient-workspace-corrections.md) records the user's thirteen issues before implementation. No skills were used. Existing Patients/Schedule controls and working gallery behavior were inspected as requested for this corrective pass. This revision awaits user visual acceptance.

## Structure

Doctors see active programs and medical history first, with no financial overview request, outstanding amount or payment tab. Reception sees outstanding balances prominently in the theme warning color, followed by patient details and upcoming visits. Payment writes retain capability checks. Both roles see next appointment and next visit.

Overview is a single full-width clinical reading column; compact fact grids are used only where facts genuinely compare, avoiding uneven paired columns and artificial blank space. Tabs use the available width with 16px page gutters. Flat section toolbars, heading rules and deliberate spacing distinguish content; removing separate card outlines avoids mismatched box heights without artificial blank space. The header has an initials avatar and clinic; phone remains in Patient Details rather than competing with identity. Attending doctors have small avatars. Document previews were removed from Overview, keeping documents in their dedicated tab. Plus Jakarta Sans and clinical blue remain the baseline. Each actionable tab uses one compact toolbar row with a consistent add action and icon-only filter when space is tight. Patient edit is an app-bar icon. Menus have icons, themed borders and destructive emphasis. Initial loading uses section/page skeletons; async transitions respect reduced motion and preserve available width.

## Preserved workflows

Active programs lead; inactive programs collapse. Appointments reuse Schedule agenda rows with doctor names and opt-in date/time inside each row. All loaded appointments appear in one list, without date grouping or past-record disclosure. Existing pagination remains available. Schedule retains time-only rows by default. Status updates refresh the patient source and balances; failure restores status without losing doctor metadata.

Appointment and note filters open the actual `AppointmentFilterSheet` used by All Appointments, including its header/footer, date presets, doctor sub-page, rectangular chips and sort rows. Optional filter content preserves patient multi-selection and package filtering. The separate look-alike sheet was removed after user feedback. Network query debounce remains at least 300ms. Notes keep linked appointment access in metadata controls.

Program documents form one folder opening the existing gallery. Private storage keys resolve through the authenticated repository, with image skeletons, retry and original fallback. Standalone documents remain individually accessible.

Deletion requires a completely empty patient for every permitted role: no appointments, payments, programs, notes, documents, medical history or nonzero session balances. Client preflight, an atomic database RPC and a delete trigger enforce this. The safeguard migration was deployed independently of unrelated migration-history differences.

## Scope and verification

Program detail now leads with treatment, followed by affected regions and findings. Medical-history and treatment-plan editors use bounded forms with a persistent Save/Cancel footer, validation, role checks and keyboard-safe content. Booking forms and payment-entry/report screens retain existing flows; this slice covers the patient and program workspaces. Fictional fixtures test role visibility, payment permissions, failure, long names at 1.8 text scale, gallery grouping, disclosures and navigation. These are not live clinical or financial transaction acceptance tests.

The final validation passed `flutter analyze` with zero issues and the full Flutter suite after updating the program-detail ordering assertion to match treatment-first priority. Tests cover width/date/header regressions, unified filters, editor save behavior, role visibility, gallery grouping, deletion guards and existing Schedule flows. The database safeguard passed disposable PostgreSQL-compatible tests for related-record categories, empty deletion and unauthorized deletion. No real patient was deleted during validation.

Initial references were Attio record hierarchy, Linear navigation and Healthie profile coverage. The user's corrections and actual app components govern this revision. See the correction audit for remaining acceptance context.
