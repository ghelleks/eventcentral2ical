# EventCentral to Icalendar

The folks at [EventCentral] have a tool for publish marketing and events
calendars on the web. They'll export to CSV. They'll export to PDF. They won't
publish in the [ICalendar] format, so let's fix that.

## Installation

You download it. That's pretty much it.

Don't forget to fix the URL. You can either edit `config.ru` to change the EventCentral::Calendar.URL variable at run-time, or edit it by hand in `lib/EventCentral.rb`

## Command-Line

This will spit out an ICalendar file for you:

~~~~~
$ ./get-ical.rb
~~~~~

## OpenShift

~~~~~
$ rhc app create ec2ical ruby-1.9 --from-code=https://github.com/ghelleks/eventcentral2ical
~~~~~

Boom.

## Bugs, Patches, Problems

File an issue: http://github.com/ghelleks/eventcentral2ical

[EventCentral]: http://www.g2planet.com/solutions.php
[ICalendar]: https://tools.ietf.org/html/rfc5545
