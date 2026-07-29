# ADR-003: Retain the Target Event Until It Ends

## Status

Accepted

## Context

The countdown reaches zero when its target event starts. Immediately replacing the event at that boundary would remove useful confirmation of what is happening now.

## Decision

Once selected, an event remains the target until its end instant.

A selection performed while an event is already underway may select that event. The result must not depend on whether the widget observed the event before its start.

Present the target in two phases:

- Before its start instant, display the remaining time until it starts.
- From its start instant up to, but not including, its end instant, display `NOW`.

At the event's end instant, advance to the next eligible event or enter the no-event state. Do not count down to the event's end.

## Consequences

- The widget confirms the current event throughout its duration.
- A widget added or refreshed during an event can immediately show that event as `NOW`.
- `NOW` has a precise interval: `start <= reference instant < end`.
- Timeline generation must include refresh boundaries at both event start and event end.
- The selected target's identity must remain stable across its transition from countdown to `NOW`.
