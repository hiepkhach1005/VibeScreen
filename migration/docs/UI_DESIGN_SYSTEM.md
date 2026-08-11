# Native UI design system

## Direction

Design ColorControl as a precise Mac control room for TVs, displays, presets and automation. The memorable element is a compact device-state ribbon showing connection, selected device, display path, active preset and automation state. Use it when it helps a decision, not as decoration.

## Shell

- Main window: sidebar + content + optional inspector using native split-view patterns.
- Menu bar: connection summary, safe quick actions, quick presets, open app, settings, quit.
- Devices: list/detail, pairing sheets, capability sections, warnings.
- Presets: selection/detail editor with ordered steps, delays, triggers and error policy.
- Settings/logs: native forms/tables, not web cards.

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
