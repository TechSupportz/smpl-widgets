# ADR-001: Implement Next-Event Countdown as a Separate Widget

## Status

Accepted

## Context

The existing countdown widget represents a user-configured date range. A future calendar-driven countdown instead discovers its target from EventKit and must account for calendar authorization, event selection, refresh timing, and the absence of an eligible event.

Making calendar discovery a mode of the existing widget would couple these distinct configuration and state models. It would also make the static countdown's behavior conditional on a data-source selection.

## Decision

Implement the calendar-driven countdown as a separate WidgetKit widget rather than as a mode of `CountdownWidget`.

The new widget may reuse presentation or calculation components where their contracts genuinely match, but it owns its own:

- widget kind and gallery entry;
- configuration intent;
- timeline provider and EventKit query behavior;
- permission, empty, and error states; and
- product-access decision.

Do not modify the static countdown's configuration or domain model to accommodate calendar events.

## Consequences

- The static countdown remains simple and independent of Calendar access.
- Calendar-specific behavior can evolve without adding conditional semantics to static countdowns.
- Users will see a separate entry in the widget gallery.
- Shared visual components must not erase the widgets' distinct domain boundaries.

