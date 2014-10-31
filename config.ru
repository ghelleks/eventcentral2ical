require 'rack/lobster'
require './lib/EventCentral.rb'
#require 'logger'

#use Rack::CommonLogger, logger

map '/health' do
  health = proc do |env|
    [200, { "Content-Type" => "text/html" }, ["1"]]
  end
  run health
end

map '/api' do
  run EventCentral::API
end

map '/' do
  run EventCentral::App
end

