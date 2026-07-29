# ADR-004: Keep the Earliest-Starting Active Event Visible

## Status

Accepted

## Context

Calendar events can overlap. More than one event may therefore be in its `NOW` phase at the same reference instant. Switching targets whenever another event starts would violate the target-stability rule.

## Decision

When multiple eligible events are active, order them by:

1. start instant, ascending;
2. end instant, ascending;
3. normalized title, ascending; and
4. EventKit event identifier, ascending.

Select the first event in that order.

Retain that event until its end instant. Then select the earliest-starting event that is still active before considering future events.

## Consequences

- A later overlapping event does not displace the current target.
- After the target ends, another overlapping event may immediately appear as `NOW`.
- If events start together, the shorter event appears first; the longer event can appear as `NOW` after the shorter one ends.
- Selection does not depend on EventKit query ordering.
