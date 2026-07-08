# ADR-012: Make Countdown a Free Widget

- Status: Accepted
- Date: 2026-07-06

## Context

Minimal Calendar is currently the only free widget. Countdown uses only user-entered configuration and calendar arithmetic; it requires no protected data permissions or external services.

## Decision

Countdown is available without the premium unlock.

- Do not add `CountdownWidget` to `PremiumConfiguration.premiumWidgetKinds`.
- Do not add Countdown to `premiumFeatureNames`.
- Do not include `isLocked` state, the premium overlay, or the premium paywall URL in the countdown implementation.
- Update the paywall subtitle to: “Minimal Calendar and Countdown are included free. One purchase unlocks everything else.”

## Consequences

- All users can place and independently configure multiple countdown widgets.
- The paywall accurately names both free widgets.
- Free access is a product policy, not an implementation shortcut based on current permission requirements.
