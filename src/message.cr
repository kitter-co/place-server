module Place
  class Message
    include JSON::Serializable

    enum Type
      Pixels
      Update
      Cooldown
      Token
      Error
    end

    getter type : Type
    getter body : String

    def initialize(@type, @body)
    end
  end
end
