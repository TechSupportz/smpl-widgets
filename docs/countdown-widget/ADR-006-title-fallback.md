# ADR-006: Allow an Optional Event Title

- Status: Accepted
- Date: 2026-07-06

## Context

The end date is the only value required to calculate a countdown. Requiring a title adds friction when a generic label is sufficient.

## Decision

The event title is editable but optional. Normalize it by trimming whitespace and newlines. If the result is empty, display `Countdown`.

## Consequences

- A user can create a valid countdown by choosing only an end date.
- The visible title is always nonempty for configured countdowns.
- The fallback is presentation behavior and is not persisted as if the user entered it.
