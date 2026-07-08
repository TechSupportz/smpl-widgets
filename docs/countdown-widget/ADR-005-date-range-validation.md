# ADR-005: Require an Ordered Date Range

- Status: Accepted
- Date: 2026-07-06

## Context

Progress is undefined when a countdown's start date occurs after its end date. A same-day range is still meaningful as an immediately completed countdown.

## Decision

A configured countdown is valid when `startDate <= endDate` after both values are normalized to calendar days.

- If `startDate == endDate`, display `0 days` and 100% progress.
- If `startDate > endDate`, do not display countdown data. Display a centered `calendar.badge.exclamationmark` SF Symbol and: “End date must be on or after start date.”

## Consequences

- Progress calculations never divide by a negative duration.
- The timeline entry and view require an invalid-configuration state.
- The date-range rule should be centralized and covered by tests when a test target is introduced.
