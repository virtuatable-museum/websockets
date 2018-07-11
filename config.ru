require 'bundler'
Bundler.require(ENV['RACK_ENV'].to_sym || :development)

service = Arkaan::Utils.MicroService.instance
  .register_as('websockets')
  .from_location(__FILE__)
  .in_standard_mode

Arkaan::Monitoring::Websocket.find_or_create_by(url: ENV['SERVICE_URL']).save

map(service.path) { run Controllers::Websockets.new }