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
      websocket.onopen {
        sockets[session_id] = websocket
        session = Arkaan::Authentication::Session.where(_id: session_id).first
        instance_id = Arkaan::Utils::MicroService.instance.instance.id.to_s
        session.update_attribute(:websocket_id, instance_id) if !session.nil?
      }
      websocket.onclose { sockets.delete(session_id) }
    end

    # Sends a message to the goven user in its dedicated websocket.
    # @param session_id [String] the unique identifier of the session linked to the user you want to send the message to.
    # @param message [String] the type of message you want to send.
    # @param data [Hash] a JSON-compatible hash to send as a JSON string with the message type.
    def send_to_sessions(session_ids, message, data)
      session_ids.each do |session_id|
        if !sockets[session_id].nil?
          EM.next_tick do
            sockets[session_id].send({message: message, data: data}.to_json)
          end
        end
      end
    end
  end
end