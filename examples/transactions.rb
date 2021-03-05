require 'pp'
require_relative '../lib/berbix'

client = Berbix::Client.new(
  client_secret: ENV['BERBIX_DEMO_CLIENT_SECRET'],
)

tokens = client.create_transaction(customer_uid: '123', template_key: 'tpk_NEItvzFxRRSVFsAF4ZlR2u0sohqBm2Cg')

pp tokens

hosted_transaction = client.create_hosted_transaction(customer_uid: '123', template_key: 'tpk_NEItvzFxRRSVFsAF4ZlR2u0sohqBm2Cg')

pp hosted_transaction.hosted_url