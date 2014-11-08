require_relative '../lib/EventCentral.rb'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

RSpec.configure do |config|
  config.formatter = "documentation"
end
