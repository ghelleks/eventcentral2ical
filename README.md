# EventCentral to Icalendar

The folks at [EventCentral] have a tool for publish marketing and events
calendars on the web. They'll export to CSV. They'll export to PDF. They won't
publish in the [ICalendar] format, so let's fix that.

## Installation

You download it. That's pretty much it.

Don't forget to set the URL in the `.env` file.

### OpenShift

~~~~~
$ rhc app create ec2ical ruby-1.9 --from-code=https://github.com/ghelleks/eventcentral2ical
~~~~~

## Usage

### Command-line

This will spit out an ICalendar file for you:

~~~~~
$ ./get-ical.rb
~~~~~

### Run Locally

Start the local environment:
~~~~~
$ rackup
~~~~~

The API is now available at http://localhost:9292/api

## Parameters

* `stakeholder`: filter by contents of the "stakeholders" field
* `region`: filter by contents of the "region_1" field
* `country`: filter by contents of the "country" field

See Examples below.

## Examples

Subscribe Red Hat's marketing calendar:

    http://eventcentral2ical-ghelleks.itos.redhat.com/

### API calls you might enjoy

Return the current version number of the API:

   `http://server/api/v1/version`

Return the full calendar as JSON:

   `http://server/api/v1/calendar.json`

Return the full calendar as ICalendar:

   `http://server/api/v1/calendar.ics`

Filter results for events that have "Public Sector" in the "stakeholders" field

   `http://server/api/v1/calendar.ics?stakeholder=Public%20Sector`
    
Filter results for events that have "Public Sector" in the "stakeholders" field

   `http://server/api/v1/calendar.ics?region=EMEA`

Filter results for events that have "USA" for the "country" field:

   `http://server/api/v1/calendar.ics?country=USA`

Complete API documentation is available via Swagger:

   `http://server/api/v1/swagger_doc`

## Bugs, Patches, Problems

File an issue: http://github.com/ghelleks/eventcentral2ical

[EventCentral]: http://www.g2planet.com/solutions.php
[ICalendar]: https://tools.ietf.org/html/rfc5545
