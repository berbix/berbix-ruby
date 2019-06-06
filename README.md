# Berbix Ruby SDK

This Berbix Ruby library provides simple interfaces to interact with the Berbix API.

## Usage

### Constructing the client

    require 'berbix'

    client = Berbix::Client.new(
      client_id: 'your_client_id_here',
      client_secret: 'your_client_secret_here',
      environment: :production,
    )

### Fetching user tokens

    user_tokens = client.exchange_code(code)

### Fetching user data

    user = client.fetch_user(user_tokens)

### User tokens from storage

    refresh_token = '' # fetched from database
    user_tokens = Berbix::UserTokens.new(refresh_token)

### Creating a user

    user_tokens = client.create_user(
      email: 'email@example.com', // previously verified email, where applicable
      phone: '+14155555555', // previously verified phone number, where applicable
      customer_uid: 'internal_customer_uid', // ID for the user in client database
    )
