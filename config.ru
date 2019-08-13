require 'bundler'
Bundler.require(ENV['RACK_ENV'].to_sym || :development)

require 'sinatra/custom_logger'

$stdout.sync = true

service = Arkaan::Utils::MicroService.instance
  .register_as('websockets')
  .from_location(__FILE__)
  .in_standard_mode

use Controllers::Websockets
run Controllers::Repartitor

at_exit { Arkaan::Utils::MicroService.instance.deactivate! }