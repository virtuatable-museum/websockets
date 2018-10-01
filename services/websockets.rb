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

    # Broadcasts a message to each and every currently connected users.
    # @param message [String] the type of message you want to broadcast to every user.
    # @param data [Hash] the additional data you want to send with the broadcasted command.
    def broadcast(message, data)
      sockets.each_key { |session_id| send_message(session_id, message, data) }
    end

    # Sends a message to all the connected sessions of a user so that he sees it on all its terminals.
    # @param username [String] the nickname of the user you want to send a message to.
    # @param message [String] the type of message you want to send.
    # @param data [Hash] a JSON-compatible hash to send as a JSON string with the message type.
    def send_to_user(account_id, message, data)
      account = Arkaan::Account.where(_id: account_id).first
      account.sessions.each do |session|
        send_message(session.id.to_s, message, data)
      end
    end

    def send_to_campaign(campaign_id, message, data)
      campaign = Arkaan::Campaign.where(_id: campaign_id).first
      campaign.accounts.each do |account|
        send_to_user(account_id, message, data)
      end
    end

    def send_to_accounts(account_ids, message, data)
      accounts = Arkaan::Account.where(:_id.in => account_ids)
      accounts.each do |session|
        send_message(session.id.to_s, message, data)
      end
    end

    def check_account(account_id)
      return true if account_id.nil?
      return !Arkaan::Account.where(_id: account_id).first.nil?
    end
    
    def check_accounts(account_ids)
      return true if account_ids.nil?
      account_ids.each do |account_id|
        return false if !check_account(account_id)
      end
      return true
    end
    
    def check_campaign(campaign_id)
      return true if campaign_id.nil?
      return !Arkaan::Campaign.where(_id: campaign_id).first.nil?
    end

  end
end