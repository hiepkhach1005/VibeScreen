# Native UI design system

## Direction

Design ColorControl as a precise Mac control room for TVs, displays, presets and automation. The memorable element is a compact device-state ribbon showing connection, selected device, display path, active preset and automation state. Use it when it helps a decision, not as decoration.

## Shell

- Main window: sidebar tree + content + optional inspector using native split-view patterns.
- Overview: one unified, vertically scrolling workspace containing dashboard
  status, presets, games, automation sources, and current-session activity.
  These areas are sections rather than separate sidebar destinations. The
  Overview destination is hidden by default and can be shown from Settings.
- Menu bar: a compact transient SwiftUI popover hosted by AppKit's public
  `NSStatusItem`/`NSPopover` APIs. Left-click and right-click on its icon toggle
  this same popover. It contains only the first saved LG TV's four Game Bar
  sliders plus Volume, refresh, open app, and quit. Do not
  repeat the selected-device explanation or preset list here. If the first
  device is not LG, show a compact explanatory state instead of silently
  controlling a later device.
  Do not repeat the selected-device explanation or preset list here. If the
  first device is not LG, show a compact explanatory state instead of silently
  controlling a later device.
- Branding: the app bundle uses the ColorControl monitor-and-controls mark in
  a blue/purple gradient for Dock/Finder; the menu-bar button uses the same
  packaged mark at 20 points without redundant text so it stays compact. A
  native TV symbol is the fallback if the packaged artwork cannot be loaded;
  hover help and VoiceOver still identify it as ColorControl.
- Devices: a selectable, expandable `Devices` parent that opens the overview
  itself, with one child destination per saved TV. A selected device renders
  connection state and remote first, platform controls next, and per-device
  automation last in one detail scroll view. Only short Add/Edit Connection
  flows remain sheets.
- Monitor: a persistent destination immediately below the Devices tree because
  it describes the Mac rather than a TV. Native grouped metric tiles separate
  utilization, temperatures, network, cooling, and power. Live values use
  monospaced digits; unavailable private sensors state the public-API
  limitation instead of displaying zero or mock data. Sampling starts and
  stops with view visibility, Settings owns the persisted interval, and a
  sidebar visibility toggle removes the destination and cancels its sampler.
- Presets: an inline Overview section with create/apply/edit/delete actions;
  its editor remains a short modal workflow.
- Settings/logs: native forms/tables, not web cards. Settings keeps only
  actionable app, live-sync, and credential-storage controls; implementation
  metadata and duplicate explanatory copy stay out of the normal flow.
- Launch at login uses a standard Settings toggle. Its inline status explains
  when macOS still requires approval and offers a direct button to the system
  Login Items pane; returning to the app refreshes the authoritative status.
- Shortcut settings: one focused native recorder button displays the first-TV
  power-toggle binding, enters an explicit “Press shortcut…” state, supports
  Escape to cancel, and shows duplicate/registration errors inline without
  replacing the last working binding. Invocation reads the TV state before
  choosing power-on or power-off. If the TV becomes unavailable after standby,
  it only attempts the safe PowerOn/Wake-on-LAN path and never guesses power-off.

## Liquid Glass

- Verify the installed SDK and deployment target before using new glass modifiers.
- Use system components first so system appearance and accessibility remain correct.
- Apply glass selectively to menu-bar popover, toolbar, floating quick controls and state surfaces.
- Keep logs, tables, forms and dense editors legible with an appropriate opaque/system material.
- Honor Reduce Transparency, Increase Contrast and Dark/Light mode.
- Never cover every surface with blur or nested translucent panels.

## Tokens

- System text styles and SF Symbols.
- Semantic colors for foreground/background/accent/success/warning/destructive.
- System control sizes and a restrained 4/8-based spacing scale.
- Monospaced digits for timings, refresh rates and technical values.
- LG range rows use a fixed 240-point label column; the slider takes all
  remaining row width with a 240-point minimum so tracks stay aligned and
  resize with the window. Range values are rounded to integers in their
  bindings; do not request per-step tick rendering because dense dotted marks
  add visual noise without adding control precision.
- Device remote shortcuts use large bordered icon buttons grouped by power,
  audio, and navigation. Every icon-only action provides a plain-language
  native hover help string plus matching VoiceOver label and hint.
- Menu-bar slider rows keep a compact fixed label/value column while the track
  fills the remaining popover width. Slider changes are sent on drag end and
  followed by a bounded TV read-back.
- Percentage labels beside LG `0…100` sliders are direct step controls in both
  the main app and menu-bar popover: left-click adds 5%, right-click (or
  Control-click) subtracts 5%, values clamp at 0/100, and one command plus
  bounded read-back follows each accepted click. The pointer cursor, hover help,
  and accessibility hint expose the interaction; non-percentage expert ranges
  do not adopt it.
- Long LG device sections use native DisclosureGroup controls: Remote/media,
  Games & HDMI, and Advanced are collapsed by default and can be expanded
  independently to reduce scrolling and keep the device page compact.
- State-driven short animations; disable nonessential motion when requested.
- All custom values centralized in Swift token types.

## Copy/accessibility

- Use sentence case and active verbs: “Apply preset”, “Wake TV”, “Pair device”.
- Name controls by user concepts, not DTO/service/dispatcher terms.
- Include VoiceOver labels, values, hints, headings and grouping.
- Never communicate state with color alone.
- Make destructive service/factory/power actions explicit and confirmed.
- Give empty/offline/permission states a useful next step.

## QA

Visual completion requires Light/Dark, resizing, menu bar, long names, empty/loading/offline/error states, keyboard navigation, VoiceOver, Reduce Motion, Reduce Transparency and Increase Contrast checks on Mac. Screenshots and results belong in progress/design evidence.

## Device screen inventory update

- Authoritative selection: `MainWindowView` owns a typed destination containing
  either a fixed section or a stable device UUID.
- Optional Overview: persisted global settings control sidebar visibility;
  hiding it safely selects Devices instead of leaving an invisible selection.
- Empty/deleted device: fall back to `Devices` with an actionable empty state.
- Offline/pairing/error: remain visible at the top of the selected device detail.
- LG control loading and bounded synchronization: owned by the visible LG detail
  task, configurable or disableable from Settings, and cancelled automatically
  when another sidebar destination is selected.
- Destructive deletion and certificate trust retain explicit confirmation.
- Accessibility: device names are sidebar labels; detail groups expose headings,
  native toggles, buttons, sliders, values, and help text.
