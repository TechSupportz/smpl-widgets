# ADR-019: Adapt to the System Color Scheme

- Status: Accepted
- Date: 2026-07-06

## Context

The reference image uses a white background, but the widget should remain native to the user's current appearance rather than forcing light mode.

## Decision

Allow the widget to adapt to light and dark mode.

- Use the system widget background rather than `alwaysWhiteWidgetStyle()`.
- Use semantic primary and secondary foreground styles for text.
- Allow the native Liquid Glass material to adapt to the environment.
- Keep the selected accent color for the radial progress layer, subject to a separate contrast decision for Black.

## Consequences

- The widget integrates with both light and dark Home Screens.
- Preview coverage must include both color schemes.
- A literal Black accent has insufficient contrast against a dark background and requires an explicit policy.
