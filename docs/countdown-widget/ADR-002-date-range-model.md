# ADR-002: Model a Countdown as a Date Range

- Status: Superseded by ADR-021
- Date: 2026-07-06

## Context

The widget displays whole days remaining and a progress indicator. Progress requires both an origin and a destination. Users may want progress to include time that elapsed before the widget was configured.

## Decision

A countdown configuration has two date-only values interpreted using the user's current calendar and timezone:

- `startDate`: defaults to the day the widget is configured and remains editable, including dates in the past.
- `endDate`: the target day toward which the widget counts.

Time-of-day is not part of the domain model. Calculations normalize both values and the current date to calendar-day boundaries before computing remaining days or progress.

The original implementation exposed both Edit Widget parameters as `DateComponents` with AppIntents `kind: .date`. ADR-021 replaces that input representation after confirming that WidgetKit still renders these parameters as free-form text fields.

## Consequences

- The widget can show meaningful elapsed progress in addition to days remaining.
- A user can backdate the start to represent the true beginning of an event or goal.
- The storage and input representation is defined by ADR-021.
- Validation behavior for an end date earlier than the start date must be defined.
