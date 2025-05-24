module Place
  class Pixels
    class Update
      include JSON::Serializable

      getter x : Int32
      getter y : Int32
      getter color : Int32
      getter user : String?

      def initialize(@x, @y, @color, @user)
      end

      def with_user(user)
        Update.new(@x, @y, @color, user)
      end

      def as_message
        Message.new(
          Message::Type::Update, to_json
        )
      end
    end

    class Pixel
      include JSON::Serializable

      property color : Int32

      @[JSON::Field(emit_null: true)]
      property user : String?

      def initialize(@color, @user)
      end
    end

    def self.db : DB::Database
      Handler.db
    end

    def self.init_table
      return if Utils.table_exists?("pixels")

      db.exec "CREATE TABLE pixels (
        x INTEGER NOT NULL,
        y INTEGER NOT NULL,
        color INTEGER NOT NULL,
        user TEXT,
        PRIMARY KEY (x, y)
      )"

      db.transaction do |tx|
        cn = tx.connection

        100.times do |y|
          100.times do |x|
            cn.exec "INSERT INTO pixels VALUES (?, ?, 0xffffff, NULL)", x, y
          end
        end
      end
    end

    def self.update(pixel : Update)
      db.exec "UPDATE pixels SET color = ?, user = ? WHERE x = ? AND y = ?", pixel.color, pixel.user, pixel.x, pixel.y

      Handler.broadcast_all(pixel.as_message)
    end

    def self.all : Array(Array(Pixel?))
      pixels = Array.new(100) { Array(Pixel?).new(100, nil) }
      rows = db.query_all "SELECT * FROM pixels", as: {Int32, Int32, Int32, String?}

      rows.each do |(x, y, color, user)|
        pixels[y][x] = Pixel.new(color, user)
      end

      pixels
    end
  end
end
