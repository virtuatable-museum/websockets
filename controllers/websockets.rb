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

      service = Services::Websockets.instance

      if !params['account_id'].nil?
        custom_error 404, 'messages.account_id.unknown' if !service.check_account(params['account_id'])
        service.send_to_account(params['account_id'], params['message'], params['data'] || {})
      elsif !params['account_ids'].nil?
        custom_error 404, 'messages.account_id.unknown' if !service.check_accounts(params['account_ids'])
        service.send_to_accounts(params['account_ids'], params['message'], params['data'] || {})
      elsif !params['campaign_id'].nil?
        custom_error 404, 'messages.campaign_id.unknown' if !service.check_campaign(params['campaign_id'])
        service.send_to_campaign(params['campaign_id'], params['message'], params['data'] || {})
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