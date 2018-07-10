module Controllers
  class Messages < Arkan::Utils::Controller
    declare_route 'post', '/' do
      session = check_session 'messages'
      check_presence 'message', 'receiver'
      Services::Websockets.send_to_user(receiver, params['message'], params['data'] || {})
      render 200, {message: 'transmitted'}.to_json
    end
  end
end