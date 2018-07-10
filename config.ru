require 'bundler'
Bundler.require(ENV['RACK_ENV'].to_sym || :development)

service = Arkaan::Utils.MicroService.instance
  .register_as('messages')
  .in_standard_mode

map('/websockets') { run Controllers::Websockets.new }
map(service.path) { run Controllers::Messages.new }