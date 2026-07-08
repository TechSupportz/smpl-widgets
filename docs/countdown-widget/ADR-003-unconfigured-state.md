# ADR-003: Represent a New Countdown as Unconfigured

- Status: Accepted
- Date: 2026-07-06

## Context

A newly placed widget has no meaningful target date. Inventing a default end date would display a countdown the user did not create.

## Decision

The end date is initially unset. Until the user supplies one through Edit Widget, the widget displays this empty-state instruction:

> Edit this widget to add a countdown

The start date defaults to the day the countdown is configured.

Present the instruction using the established widget empty-state pattern: a centered `calendar.badge.plus` SF Symbol above centered multiline text, with tertiary symbol styling and secondary text styling.

## Consequences

- A new widget never presents fabricated countdown data.
- The timeline entry and view must explicitly represent an unconfigured state.
- The end-date parameter must support an unset value.
- The empty state remains useful if a saved configuration loses or lacks its end date.
