# ADR-006: Resolve Source Calendars Through Existing Defaults

## Status

Accepted

## Context

Users may want different widget instances to watch different calendars. The app already stores a default Event Calendar selection and the Events widget already defines fallback behavior for an unset per-widget selection.

## Decision

Expose a per-widget `Calendars` parameter in the next-event countdown's configuration intent.

Resolve source calendars in this order:

1. Use the widget instance's selected calendars when that selection is nonempty.
2. Otherwise use the app's Default Event Calendars when that setting exists.
3. Otherwise query all available event calendars.

Reuse the existing calendar entity and shared-default semantics rather than introducing a second calendar-selection model.

## Consequences

- Different widget instances can target different calendar sets.
- Changing app defaults affects widget instances that do not have an explicit selection.
- An explicit per-widget selection remains isolated from later default changes.
- Deleted or inaccessible calendars must be handled without making the entire query fail.

