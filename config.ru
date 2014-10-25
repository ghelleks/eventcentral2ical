require 'rack/lobster'
require './lib/ec-to-ical.rb'

map '/health' do
  health = proc do |env|
    [200, { "Content-Type" => "text/html" }, ["1"]]
  end
  run health
end

map '/lobster' do
  run Rack::Lobster.new
end

map '/' do
  run do_ical_conversion
end
