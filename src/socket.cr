module Place
  class Socket
    property ws : HTTP::WebSocket

    property token : String?
    property email : String?

    ADMINS = File.read(Utils.relative_path("admins"))

    def initialize(@ws)
      send_pixels

      @ws.on_message do |data|
        msg  = Message.from_json(data)
        body = msg.body

        case msg.type
        when Message::Type::Token
          token = String.from_json(body)
          read_token(token)

        when Message::Type::Update
          pixel = Pixels::Update.from_json(body)
          update_pixel(pixel)
        end
      end

      @ws.on_close do |_|
        Handler.remove(self)
      end

      Handler.add(self)
    end

    def read_token(token : String)
      begin
        claims = Utils.verify_token(token)

        email = claims["email"].as_s

        if ADMINS.includes?(email)
          error "Auth Success: You are an admin"
        end

        if !email.ends_with?("@nuevaschool.org")
          error "Auth Error: Only @nuevaschool.org emails are allowed"
          return
        end

        @token = token
        @email = email

        send_cooldown
      rescue
        error "Auth Error: Token unable to be verified"
      end
    end

    def update_pixel(pixel : Pixels::Update)
      return unless email = @email

      if !Cooldowns.elapsed(email)
        error "Place Error: Cooldown has not elapsed"
        return
      end

      Cooldowns.reset(email)
      Pixels.update(pixel.with_user(email))

      send_cooldown
    end

    def send(msg : Message)
      @ws.send msg.to_json
    end

    def error(reason : String)
      send Message.new(
        Message::Type::Error, reason.to_json
      )
    end

    def send_pixels
      pixels = Pixels.all

      msg = Message.new(
        Message::Type::Pixels, pixels.to_json
      )

      send msg
    end

    def send_cooldown
      return unless email = @email
      return if ADMINS.includes?(email)

      cooldown = Cooldowns.get(email)

      msg = Message.new(
        Message::Type::Cooldown, cooldown.to_json
      )

      Handler.broadcast_email(email, msg)
    end
  end
end
