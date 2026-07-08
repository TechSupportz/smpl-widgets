# ADR-021: Use Numeric Date Entry

- Status: Accepted
- Date: 2026-07-08

## Context

WidgetKit renders App Intent `Date` and `DateComponents` parameters as free-form text fields in Edit Widget. The App Intents API does not provide a calendar-picker control style or a separate placeholder for these date parameters.

String parameters support keyboard configuration. A compact number pad does not include a separator key.

## Decision

Represent Start Date and End Date as optional strings in the widget configuration using the fixed `DDMMYYYY` format. Explain the format once in the widget description that WidgetKit displays above the configuration fields, keep the field titles as `Start Date` and `End Date`, and request the number-pad keyboard.

Set Start Date's fixed default string to `Today`. Resolve that token against the current date whenever WidgetKit requests a timeline, while continuing to parse user-entered numeric dates as `DDMMYYYY`.

Parse the strings strictly when creating the timeline. Reject values that are not exactly eight ASCII digits or do not resolve to the same calendar day. A missing or invalid Start Date falls back to the current date; a missing or invalid End Date leaves the countdown unconfigured.

## Consequences

- Date entry opens directly on a numeric keypad.
- Newly placed widgets show `Today` as the Start Date without requiring a compile-time calendar date.
- Users can see the required format above the configuration fields without repeating it in each row.
- The format is intentionally separator-free because the number pad cannot enter `/` or `-`.
- WidgetKit still owns the configuration interface, so the parameter title and empty-field prompt cannot be styled independently.
