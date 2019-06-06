require 'pp'
require_relative '../lib/berbix'

client = Berbix::Client.new(
  client_id: ENV['BERBIX_DEMO_CLIENT_ID'],
  client_secret: ENV['BERBIX_DEMO_CLIENT_SECRET'],
  api_host: ENV['BERBIX_DEMO_API_HOST'],
)

tokens = client.create_user(customer_uid: 'customer uid')

pp tokens

continuation = client.create_continuation(tokens)

pp continuation

fetched = client.exchange_code(ENV['BERBIX_DEMO_CODE'])

pp fetched

to_refresh = Berbix::UserTokens.new(fetched.refresh_token)

user = client.fetch_user(to_refresh)

pp user