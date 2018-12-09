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

      logger.info("La requête est-elle un websocket ? #{request.websocket?}")

      custom_error 400, 'creation.websocket.invalid_type' if !request.websocket?
      
      request.websocket do |ws|
        logger.info("Passage dans le bloc du contrôleur lançant la création du lien de synchronisation")
        Services::Websockets.instance.create(session.id.to_s, ws)
      end
    end

    declare_route 'post', '/purge' do
      before_checks
      Services::Websockets.instance.purge
      halt 200, {message: 'purged'}.to_json
    end

    declare_route 'post', '/messages' do
      before_checks
      # The message have to be sent, even if the additional data are optional.
      check_presence 'message', 'session_ids', route: 'messages'

      session = check_session('messages')

      Services::Websockets.instance.send_to_sessions(params['session_ids'], params['message'], params['data'] || {})

      halt 200, {message: 'transmitted'}.to_json
    end
  end
end