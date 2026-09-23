# Dark theme polish — September 23, 2026

## Audit before implementation

Scope: shared dark theme colors across patient records, schedules, forms,
navigation, and status surfaces. The light theme and screen structure are the
approved baseline. Reviewed the existing palette, theme/component tokens,
patient-workspace and profile dark captures, and production-widget previews.

- The current navy tint covers the canvas, navigation, cards, and controls. It
  makes the screen feel uniformly blue rather than giving content a clear layer.
- Near-black inset groups inside a lighter navy workspace reverse the expected
  surface hierarchy and draw unnecessary attention to containers.
- Secondary and muted text are too close to the dark surface; supporting labels
  and quiet metadata lose clarity.
- White on the current `#6C93C0` primary measures about 3.2:1, below the
  normal-size text target of 4.5:1 on primary buttons.
- `ColorScheme.fromSeed` supplies unspecified surface roles from a blue seed,
  so some Material components can diverge from the explicit palette.
- Existing dark status colors are vivid against the navy base and compete with
  patient identity. Their meaning is already carried by text and icons.

## Direction

Keep the clinical-blue identity in actions and selected states. Use a neutral,
slightly warm charcoal canvas with progressively lighter content surfaces and
quiet blue-gray dividers. Use a soft blue accent with deep ink text on filled
controls. Keep semantic success, warning, info, and error colors distinct but
less fluorescent. No layout, density, copy, or workflow changes.

The surface-layer approach follows [Atlassian elevation guidance](https://atlassian.design/foundations/elevation)
and [Carbon color guidance](https://carbondesignsystem.com/elements/color/usage/).
Contrast targets follow [Atlassian color guidance](https://atlassian.design/foundations/color).

## Validation

The shared dark palette and Material surface roles were updated in
`app_palette.dart`, `app_theme.dart`, and `clinic_colors.dart`. The light palette
and its outline role are unchanged. Production-widget captures were inspected at
360 and 1280 logical pixels for the patient workspace and booking workboard.
The latter also rendered at 320 pixels and 1.6× text scale with no exceptions.
The contrast check covers primary buttons, content text, muted text, input
outlines, and semantic status pairs. `flutter analyze --no-pub` reports no
issues; the targeted render and contrast tests pass. These previews use fictional
records and do not exercise live data or platform-specific system chrome.
