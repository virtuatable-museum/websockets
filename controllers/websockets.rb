module Controllers
  # Controller handling the websockets, creating it and receiving the commands for it.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Websockets < Sinatra::Base
    get '/' do
      session = check_session 'messages'
      if !request.websocket?
        custom_error 400, 'creation.websocket.invalid_type'
      else
        Services::Websockets.create(session.id.to_s, request.websocket)
      end
    end
  end
end