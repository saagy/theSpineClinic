# Patient workspace — Modern 2026 SaaS Architecture

This specification documents the patient detail workspace and program clinical dossier architecture established in September 2026.

## Workspace Architecture

The workspace implements a responsive SaaS two-column workspace on desktop and a high-density stacked flow on mobile:

### Desktop Viewport (`>= 960px`)
- **Sticky Patient Summary Rail (320px):** Fixed left navigation rail featuring:
  - Patient hero with monogram initials avatar and clinic badge.
  - Action pills for instant communication: direct Phone Call, WhatsApp (`wa.me`), and Edit Patient.
  - Available Sessions KPI Card displaying PT Sessions and Spinal Traction balances with interactive edit access for authorized staff.
  - Attending Clinical Staff section with monogram avatars.
  - Metadata breakdown (formatted phone number, registration date, last visit).
- **Primary Work Area (Flexible Right Pane):**
  - Segmented top workspace tab bar (`Overview`, `Programs`, `Appointments`, `Notes`, `Documents`, `Payments`).
  - Constrained max-width container (1040px) maintaining comfortable reading lines.
  - Pull-to-refresh container invalidating patient detail and tab-specific caches simultaneously.

### Mobile Viewport (`< 960px`)
- Stacked header layout with patient monogram avatar, clinic badge, and quick communication pills (Call, WhatsApp, Edit).
- Horizontally scrollable text tabs with a native animated underline.
- Adaptive overview column prioritizing role-specific tasks.

## Role-Based Structure & Information Hierarchy

- **Doctors & Senior Doctors:**
  - Overview leads directly with Active Treatment Programs, upcoming confirmed visits, target review dates, and medical history.
  - Financial data (outstanding balances, payments tab) is completely hidden.
- **Reception & Management:**
  - Overview leads with Patient Details and Outstanding Balances (highlighted in theme warning color) followed by upcoming visits.
  - Payments tab features KPI metric stat cards for Total Outstanding and Total Paid, followed by a transaction ledger with remaining balance indicators.
  - Actions like `Record Payment` and `Collect Due` are strictly gated by `canHandlePayments` capability.

## Tab & Section Implementation

1. **Active Programs:** High-density card layout highlighting anatomical condition badges, active treatment plans, program status, and creation date. Inactive/completed programs are grouped into an archived expandable section.
2. **Appointments:** Single-row SaaS toolbar with compact filter button and primary "+ Book Appointment" CTA. Renders full agenda rows with status actions, attending doctor metadata, and date/time chips.
3. **Clinical Notes:** Toolbar with "+ Add Note" CTA, displaying structured cards with author monogram, date, visit type, and note text.
4. **Documents & Imaging:** Grouped list with upload action, file type badges, thumbnail previews for scans, and integration with the private image gallery.
5. **Medical History:** Diagnostic condition tags (Diabetes with HbA1c, Hypertension, Hyperlipidemia, Rheumatology) with inline edit trigger for senior doctors.

## Program Dossier (`program_detail_screen.dart`)

The program screen is structured as a professional clinical dossier:
1. **Header Hero:** Anatomical region badges, status pill (Active, Completed, Paused), attending doctor info, and overflow menu (Edit, Change Status, Print).
2. **Prescription Table:** Treatment modalities formatted with target region pills, duration badges, specific instructions, and version history.
3. **Anatomical Findings Matrix:** 2-column clinical findings card and responsive imaging scan reel linking to full-screen lightbox inspection.

## Verification & Quality Standards

- Prior full-suite results are historical and do not establish verification of
  subsequent edits. Record the commands actually run for each correction.
- **Responsive Layout:** Tested at 360px mobile (with 1.8x text scale) and 1280px desktop.


## September 11 Surface and Lifecycle Correction

Audit: gray scaffold contrasted with white section bodies, boxed medical history
used a different hierarchy, and document folders nested a second card inside a
list panel. Compact actions inherited dark filled backgrounds. Tab reveal used
an immediate outer-scroll ensureVisible call. Intermediate widths omitted patient
facts before the sidebar became available.

The workspace now uses a continuous theme surface, flat medical-history section,
single-level document rows, outlined surface compact buttons and native animated
text tabs. Desktop context and inline patient facts share the workspace breakpoint.
Shared async transitions fade without animating layout size, and reduced motion
returns content directly. The web loading element is removed after Flutter's
first frame.

Patient appointment requests check disposal and request generation after awaits;
delayed filters and pagination cannot write into a disposed or superseded state.
The screenshot's disposed-ref failure matches this defect, but reproducing the
client's Safari keyboard/viewport distortion still requires that device workflow.

Validation: `flutter analyze` reports no issues. The final targeted rerun passed
all 13 workspace tests, 3 delayed-request/disposal regressions and 2 motion
regressions. Rendered checks covered 390px mobile and 1280px desktop in light
mode, plus 800px intermediate width in dark mode. Notes and documents tab
navigation and compact actions were inspected in the browser. The final
horizontal-scroll guard is covered by its targeted widget regression.
