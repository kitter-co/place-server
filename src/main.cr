require "./lib"

Place::Handler.init_tables

before_all do |env|
  env.response.headers["Access-Control-Allow-Origin"] = "*"
  env.response.content_type = "application/json"
end

ws "/" do |ws, env|
  auth = env.params.query["auth"]?
  raise "Client unauthorized" if auth != ENV["AUTH"]

  Place::Socket.new(ws)
end

Kemal.config.env = "production"
Kemal.run
