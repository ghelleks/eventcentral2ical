require 'rack/lobster'
require './lib/EventCentral.rb'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

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

