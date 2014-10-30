#!/usr/bin/env ruby

require 'dotenv'
require 'trollop'
require './lib/EventCentral.rb';

Dotenv.load

opts = Trollop::options do
  opt :url, "EventCentral URL to use", :type => String
  opt :country, "Filter by country contents", :type => String
  opt :stakeholder, "Filter by stakeholders contents", :type => String
  opt :region, "Filter by region_1 contents", :type => String
  opt :format, "Format of output (json, ical, txt)", :type=> String
  opt :debug, "Enable debugging output", :short => 'd'
end

if opts[:debug]
  ENV['eventcentral.loglevel'] = "Logger::DEBUG"
end

ec = EventCentral::Calendar.new
ec.filter(opts)

case opts[:format]
when "json"
  puts ec.to_json
when "ical"
  puts ec.to_ical
else
  puts ec.to_ical
end

