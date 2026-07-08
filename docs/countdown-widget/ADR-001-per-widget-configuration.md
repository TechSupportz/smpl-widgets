# ADR-001: Store Countdown Settings Per Widget Instance

- Status: Accepted
- Date: 2026-07-06

## Context

Users need to place multiple countdown widgets on the Home Screen, with each widget targeting a different event. Configuration must be available from the system's Edit Widget sheet rather than from shared settings in the container app.

The widget extension already uses `AppIntentConfiguration` for configurable widgets.

## Decision

Implement the countdown as an `AppIntentConfiguration` widget backed by a dedicated `WidgetConfigurationIntent`. The intent will own the event-specific settings, and the timeline provider will derive each widget's entries from the configuration passed to that widget instance.

Do not use `SharedSettings` as the source of truth for countdown event data.

## Consequences

- Each placed widget can have an independent countdown.
- Users configure countdowns by pressing and holding a widget and choosing Edit Widget.
- Defaults and incomplete-configuration behavior must be defined for a newly placed widget.
- Removing a widget removes access to that instance's configuration; there is no shared countdown library unless one is designed separately later.
