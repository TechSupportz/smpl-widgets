# ADR-005: Count Down to All-Day Events Without a NOW Phase

## Status

Accepted

## Context

All-day events are meaningful future calendar commitments, but treating one as active for its full day would display `NOW` for many hours and suppress timed events occurring that day.

## Decision

Allow a future all-day event to become the target and display a countdown before its calendar day begins.

An all-day event has no `NOW` phase. At midnight at the start of its event date in the user's current timezone, it becomes ineligible and the widget advances to an active timed event, the next future event, or the no-event state.

Derive this boundary using the user's current local calendar and timezone. If the user changes timezones, recompute the absolute boundary while preserving the all-day event's calendar date semantics.

## Consequences

- Users can anticipate upcoming all-day events.
- An all-day event does not suppress timed events during its day.
- The countdown boundary must be derived from a calendar day rather than treated as an ordinary timed-event instant.
- Travel can change the absolute instant at which an all-day countdown reaches zero.
- Multi-day all-day events disappear when their first day begins; they are not shown during any day of their span.
