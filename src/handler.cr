module Place
  class Handler
    @@db : DB::Database = DB.open(
      "sqlite3://#{Utils.relative_path("data.db")}"
    )

    @@sockets = [] of Socket

    def self.db : DB::Database
      @@db
    end

    def self.init_tables
      Pixels.init_table
      Cooldowns.init_table
    end

    def self.add(socket : Socket)
      @@sockets.push(socket)
    end

    def self.remove(socket : Socket)
      @@sockets.delete(socket)
    end

    def self.broadcast_all(msg : Message)
      @@sockets.each do |socket|
        socket.send msg
      end
    end

    def self.broadcast_email(email : String, msg : Message)
      @@sockets.each do |socket|
        socket.send msg if socket.email == email
      end
    end
  end
end
