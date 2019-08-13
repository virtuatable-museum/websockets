# frozen_string_literal: true

module Controllers
  # Controller handling the websockets, creating it and receiving commands.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Websockets < Arkaan::Utils::Controllers::Base
    load_errors_from __FILE__

    declare_route 'get', '/' do
      session = check_session 'messages'

      logger.info("Is WS ? #{request.websocket?}")

      unless request.websocket?
        custom_error 400, 'creation.websocket.invalid_type'
      end

      request.websocket do |ws|
        logger.info('Creating sync link with client')
        Services::Websockets.instance.create(session.id.to_s, ws)
      end
    end

    declare_route 'post', '/purge' do
      before_checks
      Services::Websockets.instance.purge
      halt 200, { message: 'purged' }.to_json
    end

    declare_route 'post', '/messages' do
      before_checks
      check_presence 'message', 'session_ids', route: 'messages'
      check_session('messages')

      service = Services::Websockets.instance
      ids = params['session_ids']
      message = params['message']
      data = params['data'] || {}

      service.send_to_sessions(ids, message, data)

      halt 200, { message: 'transmitted' }.to_json
    end
  end
end
