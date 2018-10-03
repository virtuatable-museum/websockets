require 'sinatra/custom_logger'

module Controllers
  # Controller handling the websockets, creating it and receiving the commands for it.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Websockets < Arkaan::Utils::ControllerWithoutFilter
    helpers Sinatra::CustomLogger

    load_errors_from __FILE__

    configure do
      set :logger, Logger.new(STDOUT)
    end

    declare_route 'get', '/' do
      session = check_session 'messages'
      custom_error 400, 'creation.websocket.invalid_type' if !request.websocket?
      
      request.websocket do |ws|
        Services::Websockets.instance.create(session.id.to_s, ws)
      end
    end

    declare_route 'post', '/messages' do
      # The message have to be sent, even if the additional data are optional.
      check_presence 'message', 'session_ids', route: 'messages'

      Services::Websockets.instance.send_to_sessions(params['session_ids'], params['message'], params['data'] || {})

      halt 200, {message: 'transmitted'}.to_json
    end
  end
end