module Place
  class Socket
    property ws : HTTP::WebSocket

    property token : String?
    property email : String?

    def initialize(@ws)
      send_pixels

      @ws.on_message do |data|
        msg  = Place::Message.from_json(data)
        body = msg.body

        case msg.type
        when Place::Message::Type::Token
          token = String.from_json(body)
          read_token(token)

        when Place::Message::Type::Update
          pixel = Place::Pixels::Update.from_json(body)
          update_pixel(pixel)
        end
      end

      @ws.on_close do |_|
        Place::Handler.remove(self)
      end

      Place::Handler.add(self)
    end

    def read_token(token : String)
      begin
        claims = Place::Utils.verify_token(token)

        @token = token
        @email = claims["email"].as_s

        send_cooldown
      rescue
        error "auth error: token unable to be verified"
      end
    end

    def update_pixel(pixel : Place::Pixels::Update)
      return unless email = @email

      if !Place::Cooldowns.elapsed(email)
        error "place error: cooldown has not elapsed"
        return
      end

      Place::Pixels.update(pixel)
      Place::Cooldowns.reset(email)

      send_cooldown
    end

    def send(msg : Place::Message)
      @ws.send msg.to_json
    end

    def error(reason : String)
      send Place::Message.new(
        Place::Message::Type::Error, reason.to_json
      )
    end

    def send_pixels
      pixels = Place::Pixels.full

      msg = Place::Message.new(
        Place::Message::Type::Pixels, pixels.to_json
      )

      send msg
    end

    def send_cooldown
      return unless email = @email

      cooldown = Place::Cooldowns.get(email)

      msg = Place::Message.new(
        Place::Message::Type::Cooldown, cooldown.to_json
      )

      send msg
    end
  end
end
