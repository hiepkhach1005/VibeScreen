# Visual and interaction QA checklist

## Environment

- [ ] Built with the selected stable Xcode and deployment target.
- [ ] No availability warning or fallback gap for glass-related APIs.
- [ ] Production UI does not depend on preview/sample state.

## Appearance

- [ ] Light mode inspected.
- [ ] Dark mode inspected.
- [ ] Increase Contrast inspected.
- [ ] Reduce Transparency inspected.
- [ ] Accent color changes do not destroy meaning or contrast.
- [ ] Glass is limited to navigation/control hierarchy and remains readable over varied backgrounds.
- [ ] No clipped labels, ambiguous symbols, stacked translucency, or accidental web-card styling.

## Geometry

- [ ] Main window at minimum supported size.
- [ ] Main window at normal size.
- [ ] Main window resized wider/taller.
- [ ] Menu-bar popover with short and long device names.
- [ ] Tables, forms, sidebars, inspectors, sheets, and alerts resize correctly.
- [ ] Empty, loading, long-error, and partial-offline states fit without overlap.

## Input and accessibility

- [ ] Full task can be completed with keyboard only.
- [ ] Focus order is logical and visible.
- [ ] Default, cancel, and destructive actions behave correctly.
- [ ] VoiceOver labels, values, hints, headings, and grouping are meaningful.
- [ ] Symbols are not the only accessible label.
- [ ] Status is not conveyed by color alone.
- [ ] Reduce Motion removes nonessential movement.
- [ ] Help/tooltips exist for unfamiliar compact controls.

## Behavior

- [ ] Async actions show progress and prevent harmful duplicate commands.
- [ ] Cancellation leaves state consistent.
- [ ] Offline and permission failures explain the next action.
- [ ] Destructive actions require explicit confirmation or prior opt-in.
- [ ] Menu-bar actions and main-window state stay synchronized.
- [ ] Window restoration does not reopen unsafe transient flows.

## Evidence

- [ ] Screenshots captured for required appearances and sizes.
- [ ] Relevant UI smoke tests passed.
- [ ] Source/parity rows and screen inventory updated.
- [ ] Build/test command and result recorded in `migration/PROGRESS.md`.
