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

  csv_text = fetch_csv()
  map = parse_csv(csv_text)
  cal = build_cal(map)

  calendar = proc do |env|
    [200, { "Content-Type" => "text/calendar" }, [ cal.export ] ]
  end
  run welcome

end
