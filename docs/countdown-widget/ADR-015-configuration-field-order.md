# ADR-015: Order Countdown Configuration Fields

- Status: Accepted
- Date: 2026-07-06

## Context

The system Edit Widget sheet derives its controls and ordering from the countdown configuration intent and parameter summary.

## Decision

Present fields in this order:

1. Event Name
2. Start Date
3. End Date
4. Accent Color

Event Name and End Date are optional at the storage level. Start Date defaults to the current date, and Accent Color defaults to Teal.

## Consequences

- The edit flow introduces the event label before its range and appearance.
- Start and end dates appear in chronological order.
- The parameter summary must preserve all four fields in this order.
