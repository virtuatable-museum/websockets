require 'bundler'
Bundler.require(ENV['RACK_ENV'].to_sym || :development)

service = Arkaan::Utils::MicroService.instance
  .from_location(__FILE__)
  .in_websocket_mode

map('/websockets') { run Controllers::Websockets.new }