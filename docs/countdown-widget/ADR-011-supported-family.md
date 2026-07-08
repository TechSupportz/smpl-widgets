# ADR-011: Support Only the Small Widget Family

- Status: Accepted
- Date: 2026-07-06

## Context

The reference design is composed for the square small Home Screen widget. Medium and large families require distinct layout decisions rather than scaling the same composition.

## Decision

Support only `.systemSmall` in the first countdown-widget version.

## Consequences

- The title, number, unit, and progress indicator can be tuned for one known layout.
- The widget gallery exposes no medium or large countdown variants.
- Additional families require their own designs and a later decision.
