require 'rack/lobster'
require './lib/EventCentral.rb'

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
  run EventCentral::App
end

map '/v1' do
  run EventCentral::API
end

