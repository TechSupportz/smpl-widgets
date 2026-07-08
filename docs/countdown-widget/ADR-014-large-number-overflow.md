# ADR-014: Preserve the Full Remaining-Day Value

- Status: Accepted
- Date: 2026-07-06

## Context

Countdowns may span enough time to produce three-, four-, or longer-digit remaining-day values. Fixed typography can overflow a small widget, while abbreviations change the precise value.

## Decision

Always display the complete remaining-day integer without a cap, grouping abbreviation, or compact suffix. Use a condensed heavy font and adaptive minimum scaling so the value fits its allocated region.

## Consequences

- Values such as `1000` remain exact.
- Longer values render at a smaller size than the two-digit reference example.
- The view requires a bounded number region, a one-line limit, and an intentional minimum scale factor.
