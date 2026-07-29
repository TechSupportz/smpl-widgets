# ADR-002: Require Premium Access

## Status

Accepted

## Context

The next-event countdown reads Calendar data and dynamically selects an event. It is a separate widget from the free static countdown and belongs with the app's premium calendar-powered experiences.

## Decision

Gate the next-event countdown behind the existing premium entitlement.

The widget will follow the established premium-widget behavior for gallery availability, locked presentation, and paywall routing. This decision does not change the free-access status of the static countdown widget.

## Consequences

- Users without premium access cannot use the live calendar-driven countdown.
- Existing purchase state remains the source of truth; no separate product or entitlement is introduced.
- Preview, locked, and tap behavior must be defined consistently with other premium widgets during implementation planning.

