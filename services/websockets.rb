module Services
  # This singleton service manages the different instances of websockets associated to the different users.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Websockets
    include Singleton

    # @!attribute [rw] sockets
    #   @return [Hash<String, Object>] a hash to store the sockets linked to the different sessions.
    attr_accessor :sockets

    def initialize
      @sockets = {}
    end

    # Associates the given websocket to the given session and binds actions on it.
    # @param session_id [String] the unique identifier of the session to associate the socket to.
    # @param websocket [Object] the websocket object associated to the session.
    def create(session_id, websocket)
      websocket.onopen { sockets[session_id] = websocket }
      websocket.onclose { sockets.delete(session_id) }
    end

    # Sends a message to the goven user in its dedicated websocket.
    # @param session_id [String] the unique identifier of the session linked to the user you want to send the message to.
    # @param message [String] the type of message you want to send.
    # @param data [Hash] a JSON-compatible hash to send as a JSON string with the message type.
    def send_message(session_id, message, data)
      if !sockets[session_id].nil?
        EM.next_tick do
          sockets[session_id].send({message: message, data: data}.to_json)
        end
      end
    end

    # Forwards the message by finding if it's for a campaign, a user, or several users.
    # @param params [Hash] an object containing all the needed properties for the message to be forwarded.
    def forward_message(params)
      if !params['account_id'].nil?
        send_to_account(params['account_id'], params['message'], params['data'] || {})
      elsif !params['account_ids'].nil?
        send_to_accounts(params['account_ids'], params['message'], params['data'] || {})
      elsif !params['campaign_id'].nil?
        send_to_campaign(params['campaign_id'], params['message'], params['data'] || {})
      end
    end

    # Broadcasts a message to each and every currently connected users.
    # @param message [String] the type of message you want to broadcast to every user.
    # @param data [Hash] the additional data you want to send with the broadcasted command.
    def broadcast(message, data)
      sockets.each_key { |session_id| send_message(session_id, message, data) }
    end

    # Sends a message to all the connected sessions of a user so that he sees it on all its terminals.
    # @param account_id [String] the uniq identifier of the account you're trying to reach.
    # @param message [String] the type of message you want to send.
    # @param data [Hash] a JSON-compatible hash to send as a JSON string with the message type.
    def send_to_account(account_id, message, data)
      account = Arkaan::Account.where(_id: account_id).first
      raise Services::Exceptions::ItemNotFound.new('account_id') if account.nil?
      account.sessions.each do |session|
        send_message(session.id.to_s, message, data)
      end
    end

    # Sends a message to all the users of a campaign (all accepted or creator invitations in the campaign)
    # @param campaign_id [String] the uniq identifier of the campaign.
    # @param message [String] the type of message you want to send.
    # @param data [Hash] a JSON-compatible hash to send as a JSON string with the message type.
    def send_to_campaign(campaign_id, message, data)
      campaign = Arkaan::Campaign.where(_id: campaign_id).first
      raise Services::Exceptions::ItemNotFound.new('campaign_id') if campaign.nil?
      invitations = campaign.invitations.where(:enum_status.in => ['creator', 'accepted'])
      invitations.each do |invitation|
        send_to_account(invitation.account, message, data)
      end
    end

    # Sends a message to all users in a list of accounts.
    # @param account_ids [Array<String>] the uniq identifiers of the accounts you're trying to reach.
    # @param message [String] the type of message you want to send.
    # @param data [Hash] a JSON-compatible hash to send as a JSON string with the message type.
    def send_to_accounts(account_ids, message, data)
      account_ids.each do |account_id|
        send_to_account(account_id, message, data)
      end
    end
  end
end