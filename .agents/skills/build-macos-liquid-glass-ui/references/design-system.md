# ColorControl macOS design system

## Product character

ColorControl is a precise control room for displays, televisions, presets, and automation. It should feel immediate and trustworthy: device state is visible, risky actions are deliberate, and advanced controls remain calm rather than theatrical.

The visual signature is a compact **device state ribbon** showing connection, active device, display path, and running automation. Use it where state awareness materially improves decisions; do not repeat it decoratively on every screen.

## Hierarchy and materials

Use system-native containers and let the current macOS SDK supply appearance:

- navigation/sidebar: system sidebar and selection treatment;
- toolbar and floating quick controls: eligible for system glass treatment after API availability checks;
- content: standard backgrounds, grouped forms, tables, lists, and inspectors;
- critical state: semantic status indicators plus text, never color alone;
- menu bar: compact status and actions, not full configuration forms.

Avoid stacking translucent surfaces. When transparency reduces contrast, prefer a more opaque system material. Honor Reduce Transparency without requiring a separate visual design.

## Layout model

Use a desktop information architecture:

```text
+----------------------+---------------------------------------+
| Sidebar              | Toolbar / context actions             |
| Dashboard            +---------------------------------------+
| Devices              | Device state ribbon                   |
| Presets              |                                       |
| Automation           | Primary content                       |
| Games                |                                       |
| Color Profiles       | Optional inspector / detail           |
| Logs                 |                                       |
+----------------------+---------------------------------------+
```

- Preserve window resizing; define useful minimums from content, not arbitrary screen sizes.
- Prefer split views and inspectors for selection-detail workflows.
- Prefer tables for comparable records and forms for configuration.
- Keep primary actions in predictable toolbar or bottom-trailing positions.
- Do not reproduce a mobile tab bar or web-card grid without a task-driven reason.

## Tokens

Define tokens in one Swift namespace or environment model:

- spacing: a small scale based on 4/8-point increments, with system defaults preferred;
- radii: use system component shapes; custom radii only for the signature surface;
- typography: system text styles and monospaced digits for measurements, addresses, timings, and refresh rates;
- colors: semantic foreground/background, accent, success, warning, and destructive roles; do not hard-code appearance-specific grays;
- animation: short, state-driven transitions; disable or simplify when Reduce Motion is enabled.

Do not create a parallel design-token system for values the platform already manages.

## Components

### Device row

Show name, type, connection state, current activity, and one safe primary action. Put secondary actions in context menus. Never make power-off the easiest accidental click target.

### Status ribbon

Encode actual topology and state: Mac/display, active TV, connection quality, active preset, and automation. Use text or symbols with accessible descriptions. Animate only real state transitions.

### Preset editor

Use a selection-detail layout. Make step order, delays, trigger conditions, error policy, and target device inspectable without modal nesting.

### Remote

Preserve recognizable physical groupings while adapting to keyboard navigation. Label symbol-only buttons for VoiceOver and tooltips. Separate service/factory actions behind explicit warnings.

### Logs

Use a filterable table with timestamp, subsystem, level, message, and privacy-safe metadata. Provide copy/export without exposing secrets.

## Copy

- Use sentence case and active verbs: “Wake TV”, “Apply preset”, “Open Settings”.
- Keep one action name throughout button, confirmation, progress, and result.
- Explain failures with the cause and next action.
- Make empty states actionable, such as “Add a TV by address”.
- Avoid backend terms such as dispatcher, DTO, RPC, payload, or service unless shown in diagnostic mode.

## Prohibited patterns

- blanket blur or glass on every panel;
- decorative gradients unrelated to display/device state;
- tiny low-contrast status text;
- color-only status meaning;
- destructive icon-only buttons without labels/help;
- web-style card mosaics for ordinary settings;
- custom title bars or window controls that fight macOS conventions.
