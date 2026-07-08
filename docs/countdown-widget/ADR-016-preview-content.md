# ADR-016: Use Stable Mars Trip Preview Content

- Status: Accepted
- Date: 2026-07-06

## Context

The widget gallery and redacted placeholder need representative content before a user configures a real countdown. Fixed sample content makes the composition stable and testable.

## Decision

Use this sample presentation:

- Event title: `Mars trip`
- Remaining value: `67 days`
- Progress: approximately 33%
- Accent color: Teal

Construct fixed preview dates that produce those derived values rather than hard-coding inconsistent number and progress fields.

## Consequences

- Gallery previews remain deterministic regardless of the current date.
- The sample exercises a two-digit value, title treatment, and a partial radial sector.
