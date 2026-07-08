# ADR-009: Disallow Future Start Dates

- Status: Accepted
- Date: 2026-07-06

## Context

The start date defines when progress began. A start date in the future would leave progress at zero while the remaining-day number continues counting down, which is not a useful model for this widget.

## Decision

After normalization to calendar days, a valid countdown must satisfy:

```text
startDate <= currentDate <= endDate
```

The existing completed-state rule remains an exception to the upper bound: an end date in the past is allowed and produces a completed countdown. Therefore, the complete validity rules are:

```text
startDate <= currentDate
startDate <= endDate
```

A future start date is invalid. Because AppIntents does not expose validation constraints for the system Edit Widget text field, the configuration may still be saved. In that case, display a centered `calendar.badge.exclamationmark` SF Symbol and “Start date cannot be in the future” using the established state pattern.

## Consequences

- Progress always begins on or before the day the widget is viewed.
- The implementation must validate the start date against the current calendar day whenever it creates a timeline.
- A configuration can transition from invalid to valid automatically when its future start day arrives if the system allows it to be saved.
- The widget does not silently replace the configured start date with today.
