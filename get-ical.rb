#!/usr/bin/env ruby

require './lib/EventCentral.rb';

puts EventCentral::Calendar.new.to_ical
