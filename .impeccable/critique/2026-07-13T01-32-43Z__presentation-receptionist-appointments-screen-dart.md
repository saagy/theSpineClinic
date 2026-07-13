---
target: receptionist appointment booking and tomorrow preparation workflow
total_score: 18
p0_count: 0
p1_count: 3
timestamp: 2026-07-13T01-32-43Z
slug: presentation-receptionist-appointments-screen-dart
---
Method: dual-agent (A: /root/ux_assessment · B: /root/evidence_assessment)

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|---|---:|---|
| 1 | Visibility of system status | 3 | Loading, errors, and appointment status are visible; shared call progress and ownership are not. |
| 2 | Match with the real world | 2 | Today/Upcoming/All does not match the receptionist's find-call-confirm-book routine. |
| 3 | User control and freedom | 3 | Edit, cancel, restore, retry, refresh, and filter clearing exist; undo is limited. |
| 4 | Consistency and standards | 2 | Cards are consistent, but each tab exposes different capabilities and semantics. |
| 5 | Error prevention | 1 | No due-date source, duplicate booking guard, slot collision check, or absence guard. |
| 6 | Recognition rather than recall | 1 | Staff must remember patients and call progress across tabs, patient screens, and phone calls. |
| 7 | Flexibility and efficiency | 1 | No dashboard booking action, shared claims, batch actions, or bulk reassignment. |
| 8 | Aesthetic and minimalist design | 3 | The presentation is clean, but Upcoming duplicates All and lacks an operational purpose. |
| 9 | Error recovery | 2 | Common request failures recover; coordination and absence mistakes have no dedicated recovery flow. |
| 10 | Help and documentation | 0 | No contextual explanation of the tab model or confirmation workflow. |
| **Total** |  | **18/40** | **Poor for the requested operational workflow** |

## Anti-Patterns Verdict

### LLM assessment

A reliable visual AI-slop verdict was not possible because the authenticated Flutter UI was not exposed to the in-app browser. Source structure suggests a consistent Material product vocabulary rather than decorative AI styling. The larger problem is generic information architecture: three passive list tabs where the real job is a collaborative daily workflow.

### Deterministic scan

The detector returned zero findings. This is not a reliable clean result for Flutter: the direct Dart file used only the generic regex path, and directory walking excluded Dart files. Manual source inspection found issues the detector missed, including hardcoded labels, a 245-line primary file despite its under-200 comment, and raw Divider usage in the doctor now indicator.

### Visual overlays

No overlay was created. The browser client initialized, but the in-app browser returned `Browser is not available: iab`; no controllable session or mutable injection surface was available.

## Overall Impression

The user is correct. The surface manages appointments that already exist; it does not manage the work required to create tomorrow's schedule. Upcoming provides a convenient future list, but it cannot show unbooked patients, shared call progress, or doctor coverage. The biggest opportunity is to replace passive future browsing with a shared Tomorrow workboard.

## What's Working

- Shared appointment cards provide consistent patient, time, type, status, and action presentation across receptionist and doctor screens.
- Loading, error, empty, data, retry, and pull-to-refresh states are mostly present; All is especially complete.
- Once reached, booking preselects the patient, loads assigned doctors, previews slots, checks package balance, and confirms success.

## Priority Issues

### [P1] The app cannot identify who is due tomorrow

Upcoming begins with existing appointment rows, so every patient shown is already booked. Last attended visit is historical information, not a scheduling rule. Define and persist one source of truth for due work: clinician-set next date, recurring treatment weekdays, or a manually created booking task. Then build Tomorrow from that source.

Suggested command: `$impeccable shape`

### [P1] Multiple receptionists have no shared coordination state

There is no claimed-by receptionist, call outcome, confirmation state, update time, or atomic claim. Staff can duplicate calls or bookings while each believes the work is still open. Add a small server-backed queue with Pending, Calling, Call back, Declined, and Booked states; show owner and last update; make claim and booking checks atomic.

Suggested command: `$impeccable harden`

### [P1] Doctor absence has no safe bulk workflow

Current editing reassigns doctors one appointment at a time. The former replacement table was removed, so there is no date-bounded coverage feature. Add Doctor unavailable for a selected doctor and date, preview every affected booking, then bulk reassign, reschedule, or cancel in one transaction with conflict warnings and audit history.

Suggested command: `$impeccable shape`

### [P2] Past Scheduled appointments look current

Cards style by stored status only. A Scheduled appointment from a past day looks like a valid future booking. Do not fade it like Cancelled; keep it readable and label it `Past scheduled · Needs action`, with a warning treatment and a Needs attention group.

Suggested command: `$impeccable clarify`

### [P2] Call and booking actions are outside the appointment workspace

The appointments dashboard exposes no Book action. Receptionists must switch to Patients, open a patient, and launch booking from there. Tomorrow rows should show large Call and Book actions; booking should open with patient, assigned doctors, and tomorrow's date prefilled.

Suggested command: `$impeccable layout`

## Recommended Information Architecture

Replace the top-level Upcoming tab with Tomorrow. Keep All for lookup/history and add a Future quick filter there.

Tomorrow should show:

- A summary: Booked, To call, Call back, and Unresolved.
- A horizontal doctor filter plus a calendar escape hatch.
- A To contact section containing due-but-unbooked patients, with phone, assigned doctor, owner, and contact outcome.
- A Booked section showing tomorrow's actual schedule, grouped by doctor or ordered by time.
- Call and Book actions on every relevant row.
- A visible completion state: `Tomorrow is fully scheduled` only when no queue items remain unresolved.

Today should remain operational, but status sectioning should become filter chips over one chronological timeline if a now indicator is added. A now line is misleading across the current Checked In → Scheduled → Cancelled grouping. Past Scheduled rows should appear as Needs attention above or within the timeline.

## Persona Red Flags

### Alex, power receptionist

Alex cannot claim a batch of calls, mark outcomes quickly, see remaining work by doctor, or bulk reassign an absent doctor's appointments. Upcoming contains an unbounded future list instead of the day's workload.

### Jordan, newer receptionist

Jordan cannot infer the practical difference between Upcoming and All, and may read Scheduled as Confirmed. Empty states do not explain how tomorrow is prepared, and important actions are hidden in details or an ellipsis menu.

### Casey, distracted mobile receptionist

An external phone call breaks context. Returning to the app shows no persistent marker of who was called or what happened. Booking is several screens away and ownership is invisible.

## Minor Observations

- Upcoming includes cancelled appointments and has no search, doctor filter, or date limit.
- All defaults to the current month despite being labeled All.
- Patient last-visit sorting is client-side after a differently sorted paginated query, so it is not a reliable global due list.
- The doctor now line reads current time only on rebuild and is absent for an empty day.
- Booking currently has no patient/time or doctor/time collision constraint; the recurring RPC inserts requested slots without an overlap check.

## Questions to Consider

- What creates the due-tomorrow population: fixed weekly treatment days, a clinician-set next date, or a receptionist-created task?
- Does Confirmed mean confirming an appointment that already exists, or calling a patient before creating it?
- Should receptionists claim tasks manually, or should work be divided automatically by doctor or branch?
- For a doctor emergency, is the usual resolution one covering doctor for the day, or individual patient rescheduling?
