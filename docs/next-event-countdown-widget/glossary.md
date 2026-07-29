# Next-Event Countdown Widget Glossary

### Static countdown widget

The existing widget whose target date and progress range are entered explicitly by the user. It does not discover targets from Calendar data.

### Next-event countdown widget

A separate future WidgetKit widget that discovers an eligible calendar event and counts down to it. Its precise event-selection rules remain to be decided.

### Eligible event

A calendar event that satisfies all configured selection rules and can therefore become the widget's countdown target. An event already underway may be eligible; the widget does not need to have observed its start.

### Target event

The calendar event currently presented by the widget. Before it starts, the widget counts down to it; while it is underway, the widget displays `NOW`; when it ends, the widget advances.

### Reference instant

The instant used consistently to select an eligible event and calculate its remaining time for a timeline entry.

### NOW phase

The half-open interval from the target event's start instant through, but not including, its end instant. The widget displays `NOW` during this phase rather than a countdown value.

### Overlapping active events

Two or more eligible events whose `NOW` phases contain the same reference instant. They are ordered by start, end, normalized title, and EventKit identifier. The selected event remains visible until it ends, after which another still-active event may become the target.

### All-day target

An eligible all-day event whose calendar day has not begun in the user's current timezone. The widget may count down to local midnight at the start of that date, but it never displays `NOW` for the event.

### Premium access

The app's existing paid entitlement. The next-event countdown requires this entitlement; it does not introduce a separate purchase.

### Source calendars

The calendars queried for target events. A nonempty per-widget selection takes precedence, followed by the app's Default Event Calendars, followed by all available event calendars.

### Excluded commitment

A canceled event or an invitation the current user has declined. Excluded commitments cannot become targets, even if their time range would otherwise qualify.
