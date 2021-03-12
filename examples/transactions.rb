require 'pp'
require_relative '../lib/berbix'

client = Berbix::Client.new(
  client_secret: ENV['BERBIX_DEMO_CLIENT_SECRET'],
)

tokens = client.create_transaction(customer_uid: 'ADD_UID_HERE', template_key: 'tpk_ADD_TEMPLATE_KEY_HERE')

pp tokens

hosted_transaction = client.create_hosted_transaction(customer_uid: 'ADD_UID_HERE', template_key: 'tpk_ADD_TEMPLATE_KEY_HERE', :hosted_options => {:completion_email => "ADD_EMAIL_HERE"})

pp hosted_transaction.hosted_url