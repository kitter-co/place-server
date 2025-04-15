module Place
  class Handler
    @@db : DB::Database = DB.open(
      "sqlite3://#{File.join(
        File.dirname(Process.executable_path.not_nil!),
        "data.db"
      )}"
    )

    @@sockets = [] of Place::Socket

    def self.db : DB::Database
      @@db
    end

    def self.init_tables
      Place::Pixels.init_table
      Place::Cooldowns.init_table
    end

    def self.add(socket : Place::Socket)
      @@sockets.push(socket)
    end

    def self.remove(socket : Place::Socket)
      @@sockets.delete(socket)
    end

    def self.broadcast_all(msg : Place::Message)
      @@sockets.each do |socket|
        socket.send msg
      end
    end

    def self.broadcast_email(email : String, msg : Place::Message)
      @@sockets.each do |socket|
        socket.send msg if socket.email == email
      end
    end
  end
end
