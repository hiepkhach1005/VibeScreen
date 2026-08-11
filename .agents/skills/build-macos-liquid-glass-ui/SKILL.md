---
name: build-macos-liquid-glass-ui
description: Design, implement, and visually verify native macOS interfaces for ColorControl using SwiftUI, selective AppKit bridges, current Liquid Glass APIs, Apple interaction patterns, menu-bar controls, accessibility, and complete loading/empty/error states. Use for any task that creates or reshapes SwiftUI views, MenuBarExtra or NSStatusItem experiences, navigation, settings, device dashboards, remotes, presets, layout, design tokens, assets, copy, animations, previews, or UI tests under macOS/ColorControlMac.
---

# Build macOS Liquid Glass UI

Create a distinctly native control utility, not a web dashboard inside a Mac window. Preserve the task model discovered in legacy source while redesigning its information architecture for macOS.

## Required context

Read `AGENTS.md`, `migration/PROGRESS.md`, `migration/DECISIONS.md`, and the current NEXUS/design documents when present. Read only the legacy UI and service files needed to understand the feature being designed; never copy Razor, WinForms, WPF, HTML, or CSS.

Load these references as needed:

- Read `references/design-system.md` before establishing tokens, components, materials, navigation, or interaction patterns.
- Read `references/screen-inventory.md` before adding or reorganizing a screen, menu-bar section, sheet, inspector, or settings pane.
- Read `references/visual-qa-checklist.md` before declaring UI work complete.

Verify current API availability against the installed stable SDK and Apple documentation before using Liquid Glass-specific modifiers. Record deployment-target implications in the platform map or an ADR.

## Workflow

1. **Define the job.** Name the user, the single task of the surface, the information needed to complete it, and every state: loading, empty, offline, pairing, permission denied, partial failure, destructive confirmation, and success.
2. **Trace behavior.** Link controls to source-map and parity-matrix rows. Do not invent commands or omit legacy behavior because the old UI is unattractive.
3. **Design in two passes.** First propose compact tokens, hierarchy, layout alternatives, and one product-specific signature. Then critique whether the plan is recognizably ColorControl rather than a generic settings app; revise before coding.
4. **Choose native containers.** Prefer `NavigationSplitView`, `Table`, `Form`, `Settings`, `Toolbar`, `Commands`, `MenuBarExtra`, sheets, alerts, inspectors, and system pickers. Bridge to AppKit only behind a narrow wrapper when SwiftUI cannot meet the requirement.
5. **Implement states first.** Make the same view handle live, unavailable, permission-blocked, and preview data without production mocks leaking into runtime.
6. **Add accessibility and keyboard behavior.** Set semantic labels, help, values, focus order, shortcuts, default/cancel actions, and destructive roles while implementing each component.
7. **Verify visually and behaviorally.** Build on macOS, inspect screenshots, test resizing and menu-bar constraints, run UI tests, and complete the visual QA checklist.
8. **Update project memory.** Update the design system, screen inventory, parity row, tests, and `migration/PROGRESS.md`.

## Design rules

- Let system controls provide current Apple styling. Use glass as a hierarchy layer for navigation and controls, not as decoration or a blanket blur.
- Keep forms, logs, tables, and dense preset editors calm and legible. Reserve visual emphasis for device state and primary actions.
- Use system typography, semantic colors, SF Symbols, system control sizes, and centralized tokens. Never scatter magic spacing, corner radius, opacity, or colors through views.
- Spend distinctiveness in one justified signature: a live device/display state ribbon or connection topology is preferred. Keep surrounding surfaces restrained.
- Use plain, action-oriented copy. Name controls after concepts users recognize, not implementation details.
- Treat menu-bar UI as a compact command surface. Put full configuration and long lists in the main window.
- Make dangerous actions unmistakable and require confirmation or prior explicit opt-in.
- Respect light/dark appearance, Reduce Transparency, Reduce Motion, Increase Contrast, keyboard-only use, and VoiceOver.
- Do not reuse the Windows `.ico`; use a macOS asset catalog and symbols appropriate to each context.
- Do not create custom controls when a standard control communicates the same behavior better.

## Completion evidence

Require all of the following before marking a UI feature complete:

- source/parity rows linked;
- all states implemented;
- preview/sample data isolated from production;
- macOS build and relevant UI tests passed;
- screenshots reviewed in required appearances and sizes;
- accessibility checklist passed;
- no private API or web-based UI dependency introduced;
- design and progress documents updated.
