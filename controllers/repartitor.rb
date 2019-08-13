# frozen_string_literal: true

module Controllers
  # Controller handling the websockets, creating it and receiving commands.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Repartitor < Arkaan::Utils::Controllers::Checked
    load_errors_from __FILE__

    configure do
      set :logger, Logger.new(STDOUT)
    end

    declare_status_route

    declare_route 'get', '/repartitor/url' do
      service = Arkaan::Monitoring::Service.where(key: 'websockets').first
      instance = service.instances.where(active: true, running: true).sample
      base_url = instance.url.gsub(/^http/, 'ws').gsub(%r{/$}, '')
      halt 200, { url: "#{base_url}/websockets" }.to_json
    end

    declare_route 'post', '/repartitor/messages' do
      # The message have to be sent, even if the additional data are optional.
      check_presence 'message', route: 'messages'
      # A message can be sent to either :
      # - one user
      # - several users
      # - all the users of a single campaign.
      check_either_presence(
        'account_id',
        'campaign_id',
        'account_ids',
        'username',
        route: 'messages',
        key: 'any_id'
      )

      session = check_session('messages')

      logger.info("Arrivée dans l'envoi de message pour les paramètres :")
      logger.info(params.to_json)

      begin
        Services::Repartitor.instance.forward_message(session, params)
        halt 200, { message: 'transmitted' }.to_json
      rescue Services::Exceptions::ItemNotFound => e
        custom_error 404, e.to_s
      end
    end
  end
end
