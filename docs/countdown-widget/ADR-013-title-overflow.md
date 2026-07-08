# ADR-013: Keep the Event Title on One Line

- Status: Accepted
- Date: 2026-07-06

## Context

The small-widget composition reserves most of its vertical space for the remaining-day number. User-entered event titles can be arbitrarily long.

## Decision

Render the visible event title on one line using the condensed treatment from the reference design. Allow it to scale down to a defined minimum scale factor; if it still does not fit, truncate the tail.

Apply the same behavior to the `Countdown` fallback title.

## Consequences

- Long titles cannot push the number, unit, or progress indicator out of position.
- Some titles will be abbreviated visually.
- The full configured title remains stored in the widget configuration.
