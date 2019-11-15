require 'pp'
require_relative '../lib/berbix'

client = Berbix::Client.new(
  api_secret: ENV['BERBIX_DEMO_CLIENT_SECRET'],
  api_host: ENV['BERBIX_DEMO_API_HOST'],
)

tokens = client.create_transaction(customer_uid: 'customer uid')

pp tokens

continuation = client.create_continuation(tokens)

pp continuation

fetched = client.exchange_code(ENV['BERBIX_DEMO_CODE'])

pp fetched

to_refresh = Berbix::Tokens.from_refresh(fetched.refresh_token)

transaction = client.fetch_transaction(to_refresh)

pp transaction