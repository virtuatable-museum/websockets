module Controllers
  # Controller handling the websockets, creating it and receiving the commands for it.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Websockets < Arkaan::Utils::Controller

    get '/' do
      session = check_session 'messages'
      if !request.websocket?
        custom_error 400, 'creation.websocket.invalid_type'
      else
        Services::Websockets.create(session.id.to_s, request.websocket)
      end
    end

    get '/messages' do
      session = check_session 'messages'
      check_presence 'message', 'receiver'
      Services::Websockets.send_to_user(receiver, params['message'], params['data'] || {})
      render 200, {message: 'transmitted'}.to_json
    end
  end
end