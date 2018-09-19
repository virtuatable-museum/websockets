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
      
      if !request.websocket?
        custom_error 400, 'creation.websocket.invalid_type'
      else
        request.websocket do |ws|
          Services::Websockets.instance.create(session.id.to_s, ws)
        end
      end
    end

    declare_route 'post', '/messages' do
      before_checks
      check_presence 'message', 'receiver', route: 'messages'

      logger.info "Sending a [#{params['message']}] message to : #{params['receiver']}"

      EM.next_tick do
        Services::Websockets.instance.send_to_user(params['receiver'], params['message'], params['data'] || {})
      end
      halt 200, {message: 'transmitted'}.to_json
    end

    declare_route 'post', '/broadcast' do
      before_checks
      check_presence 'message', route: 'messages'

      EM.next_tick do
        Services::Websockets.instance.broadcast(params['message'], params['data'] | {})
      end
      halt 200, {message: 'broadcasted'}.to_json
    end
  end
end