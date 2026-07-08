# ADR-010: Configure the Accent from Standard iOS Color Presets

- Status: Accepted
- Date: 2026-07-06

## Context

Users can place multiple independently configured countdown widgets. A per-widget accent helps distinguish them, while an unrestricted color editor would add complexity to the system Edit Widget sheet.

## Decision

Expose an accent-color parameter in the countdown's configuration intent. Persist the selected preset as a primitive `String`, and provide the finite list through a `DynamicOptionsProvider` with teal as its default result:

- Red
- Orange
- Yellow
- Green
- Mint
- Teal
- Cyan
- Blue
- Indigo
- Purple
- Pink
- Brown
- Monochrome

The primitive selector replaces both the original `AppEnum` and a subsequent `AppEntity` implementation. In each case, the system editor displayed a changed value while the timeline provider continued receiving the teal fallback. Persisting the name directly avoids enum-case metadata and entity-rehydration failures. Gray is intentionally excluded because it would blend into the neutral/glass portion of the indicator. Monochrome renders black in light mode and white in dark mode.

The selected color applies to the normal colored circle beneath the Liquid Glass progress layer. It does not change the widget's white background or primary text.

## Consequences

- Each widget instance retains its own accent selection.
- The system Edit Widget UI presents a simple finite list rather than a custom color picker.
- The configuration stores the selected display name directly, without a secondary entity lookup.
- Monochrome remains visible in both system appearances.
