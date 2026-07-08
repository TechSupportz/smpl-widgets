# ADR-007: Use a Layered Radial Liquid Glass Progress Indicator

- Status: Superseded by ADR-020
- Date: 2026-07-06

## Context

The reference design includes a compact circular element at the lower-left. It represents elapsed progress through the configured date range. The project targets iOS 26.1, where native Liquid Glass APIs are available.

## Decision

Build the indicator from two circles in a stack:

1. A normal accent-colored circle underneath.
2. A native Liquid Glass circle above it.

The colored circle is revealed through a continuous radial sector mask whose sweep angle is `progress × 360°`:

- 0% reveals none of the colored circle.
- 25% reveals one quarter of the circle.
- 50% reveals one semicircle.
- 100% reveals the full circle.

All intermediate progress fractions map to their corresponding intermediate angle. The sector begins at 12 o'clock and sweeps clockwise. Do not use a conventional stroked progress ring, a linear fill, or quantized progress steps.

## Consequences

- The indicator matches the layered material direction of the reference design.
- No pre-iOS-26 visual fallback is required under the current deployment target.
- Progress values still remain clamped from 0% through 100%.
- The radial mask requires a custom shape or equivalent sector clipping implementation.
