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
      # The message have to be sent, even if the additional data are optional.
      check_presence 'message', route: 'messages'
      # A message can be sent to either : one user, several users, and all the users of a single campaign.
      check_either_presence 'account_id', 'campaign_id', 'account_ids', route: 'messages', key: 'any_id'

      begin
        Services::Websockets.instance.forward_message(params)
        halt 200, {message: 'transmitted'}.to_json
      rescue Services::Exceptions::ItemNotFound => exception
        custom_error 404, exception.to_s
      end
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