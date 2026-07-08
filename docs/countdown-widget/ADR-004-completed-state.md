# ADR-004: Clamp Completed Countdowns at Zero

- Status: Accepted
- Date: 2026-07-06

## Context

Once a countdown's end date arrives, the remaining-day calculation reaches zero and would become negative on later days unless the presentation defines a completed state.

## Decision

On the end date and every day afterward:

- Display `0` as the remaining-day value.
- Continue to display the unit as `days`.
- Clamp progress to 100%.
- Retain the configured event title.
- Never display a negative remaining-day value.

## Consequences

- Completed countdown widgets remain visually stable and recognizable.
- Users must edit or remove a completed widget manually.
- A distinct completion message or automatic reset can be considered later without changing the date-range model.

## Unit inflection

Use `day` only when the remaining value is exactly 1. Use `days` for every other value, including 0.
