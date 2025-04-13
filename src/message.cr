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

    property type : Type
    property body : String

    def initialize(@type, @body)
    end
  end
end
