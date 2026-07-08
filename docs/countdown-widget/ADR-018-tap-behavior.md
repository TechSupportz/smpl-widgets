# ADR-018: Do Not Add a Countdown Deep Link

- Status: Accepted
- Date: 2026-07-06

## Context

Countdown settings live in the system Edit Widget sheet, and the container app has no countdown-management screen.

## Decision

Do not attach a countdown-specific `widgetURL` or introduce a new URL route. Tapping the widget may use the system's default app-opening behavior.

## Consequences

- Widget editing remains in one place.
- The implementation requires no unused countdown destination in the container app.
- Premium paywall routing does not apply because Countdown is free.
