module Place
  module Utils
    PROJECT_ID = "nueva-place"

    def self.table_exists?(table : String) : Bool
      res = Place::Handler.db.query_one? "SELECT name FROM sqlite_master WHERE type='table' AND name=?", table, as: String
      !!res
    end

    def self.verify_token(token : String) : JSON::Any
      header_sgmt = token.split(".", 3)[0]

      header = JSON.parse(Base64.decode_string(header_sgmt))
      kid = header["kid"].as_s

      url  = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"
      keys = JSON.parse(HTTP::Client.get(url).body)

      pem  = keys[kid].as_s

      cert = OpenSSL::X509::Certificate.new(pem)
      pub_key = cert.public_key.as(OpenSSL::PKey::RSA).to_pem

      claims, _ = JWT.decode(token, pub_key, JWT::Algorithm::RS256, true)

      issuer = "https://securetoken.google.com/#{PROJECT_ID}"
      valid  = claims["iss"] == issuer && claims["aud"] == PROJECT_ID

      raise "invalid issuer or audience" unless valid
      claims
    end
  end
end
