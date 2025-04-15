module Place
  class Cooldowns
    def self.db : DB::Database
      Place::Handler.db
    end

    def self.init_table
      return if Place::Utils.table_exists?("cooldowns")

      db.exec "CREATE TABLE cooldowns (email TEXT PRIMARY KEY, last_time INTEGER)"
    end

    def self.get(email : String) : Int32
      res = db.query_one? "SELECT last_time FROM cooldowns WHERE email = ?", email, as: Int32

      if res
        res
      else
        db.exec "INSERT INTO cooldowns VALUES (?, ?)", email, 0
        0
      end
    end

    def self.elapsed(email : String) : Bool
      last_time = get(email)
      cur_time  = Time.local.to_unix

      cur_time - last_time >= 5 * 60
    end

    def self.reset(email : String)
      cur_time = Time.local.to_unix
      db.exec "UPDATE cooldowns SET last_time = ? WHERE email = ?", cur_time, email
    end
  end
end
