# Countdown Widget Glossary

## Accepted terms

### Countdown widget instance

One free placement of the countdown widget on the Home Screen. Each instance owns an independent configuration supplied by WidgetKit through its configuration intent.

### Countdown configuration

The event-specific values exposed in the system Edit Widget sheet. These values are not global app settings.

### Event title

An optional user-provided label for a configured countdown. Whitespace-only values are treated as empty and displayed as `Countdown`.

### Unconfigured countdown

A countdown widget instance with no end date. It displays `calendar.badge.plus` and “Edit this widget to add a countdown” instead of countdown data.

## Terms pending definition

### Start date

The first calendar day in the countdown's progress range. It defaults to the day the widget is configured and can be changed to today or a date in the past, but not to a future date.

### End date

The optional target calendar day toward which the widget counts. It begins unset and is supplied by the user through Edit Widget.

### Countdown range

The date-only interval from the configured start date through the configured end date, interpreted using the user's current calendar and timezone. A valid range requires the start date to be on or before the end date.

### Remaining days

The nonnegative whole-calendar-day distance from the current date to the end date. It reaches zero on the end date and remains clamped at zero afterward. Its unit is `day` for exactly 1 and `days` otherwise.

### Progress

The elapsed whole-calendar-day distance divided by the countdown range's total whole-calendar-day distance, clamped from 0% through 100%. A same-day range has 100% progress.

### Completed countdown

A configured countdown whose current calendar day is on or after its end date. It displays zero remaining days and 100% progress while retaining its title.

### Invalid countdown

A configured countdown that violates a date invariant, such as a start date after its end date or a start date in the future. It displays `calendar.badge.exclamationmark` and explanatory text instead of countdown data.

### Progress indicator

The circular lower-left element that visualizes elapsed progress. A continuous radial sector begins at 12 o'clock and sweeps clockwise. The colored sector is blurred beneath a translucent semantic neutral circle and subtle rim to create a WidgetKit-compatible frosted appearance.

### Accent color

A per-widget selection from a finite set of standard SwiftUI/iOS named colors. It colors the progress indicator's lower circle and defaults to teal.

### Monochrome accent

An adaptive accent preset that renders black in light mode and white in dark mode so the radial sector remains visible.
