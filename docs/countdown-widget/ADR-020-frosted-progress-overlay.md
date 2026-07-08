# ADR-020: Replace Liquid Glass with a Frosted Progress Overlay

- Status: Accepted
- Date: 2026-07-08

## Context

WidgetKit snapshot rendering does not reliably render the native Liquid Glass effect used by the progress indicator. The Xcode widget preview showed only the colored radial sector, with no visible neutral circle above it.

## Decision

Use a deterministic SwiftUI shape composition instead of `glassEffect`:

1. Render the accent-colored radial sector.
2. Apply a small blur and clip it to the circular boundary.
3. Overlay a semantic secondary-colored circle at low opacity.
4. Add a subtle semantic primary-colored rim.

The overlay adapts automatically in light and dark appearances.

## Consequences

- The frosted circle renders consistently in WidgetKit snapshots.
- The blurred accent retains the soft visual character of the original design.
- The implementation no longer depends on Liquid Glass behavior inside widgets.
- Light and dark widget previews must remain part of visual validation.
