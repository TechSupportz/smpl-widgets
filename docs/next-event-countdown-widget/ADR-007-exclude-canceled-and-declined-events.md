# ADR-007: Exclude Canceled Events and Declined Invitations

## Status

Accepted

## Context

Calendar queries may return canceled events or invitations the user explicitly declined. Neither represents an event the user intends to attend.

## Decision

An event is ineligible when either:

- its EventKit status is canceled; or
- the current user's participant status is declined.

This filtering applies before active-event ordering and future-event selection.

Eligibility for tentative, pending, and unknown participation states remains to be decided.

## Consequences

- Removed commitments do not become countdown targets.
- A target that later becomes canceled or declined must disappear on the next successful calendar refresh.
- Selection logic must safely handle events without organizer or attendee metadata.

