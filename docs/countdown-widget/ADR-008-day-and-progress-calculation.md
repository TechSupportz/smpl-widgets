# ADR-008: Calculate Countdown State from Calendar-Day Distance

- Status: Accepted
- Date: 2026-07-06

## Context

The remaining-day number and radial progress indicator must use the same date boundaries. Time-of-day and daylight-saving transitions must not introduce fractional or off-by-one results.

## Decision

Normalize the start date, end date, and current date using the user's current calendar. For a valid range with a positive total duration:

```text
totalDays = calendar days from startDate to endDate
elapsedDays = calendar days from startDate to currentDate
remainingDays = max(0, calendar days from currentDate to endDate)
progress = clamp(elapsedDays / totalDays, 0 ... 1)
```

For a same-day range where `totalDays == 0`, progress is 100% and remaining days is zero.

Example for July 1 through July 11:

| Current date | Remaining days | Progress |
|---|---:|---:|
| July 1 | 10 | 0% |
| July 6 | 5 | 50% |
| July 11 | 0 | 100% |

## Consequences

- The number and progress indicator reach their boundaries together.
- Calculations use calendar arithmetic rather than fixed 86,400-second intervals.
- The widget needs a new timeline entry at the start of each local calendar day while active.
