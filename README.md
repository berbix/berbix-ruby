# Berbix Ruby SDK

This Berbix Ruby library provides simple interfaces to interact with the Berbix API.

## Installation

    gem install berbix-ruby

## Usage

### Constructing a client

    require 'berbix'

    // Construct the client, providing at least client_id and client_secret
    client = Berbix::Client.new(
      client_id: 'your_client_id_here',
      client_secret: 'your_client_secret_here',
      environment: :production,
    )

### Create a transaction

    transaction_tokens = client.create_transaction(
      customer_uid: 'internal_customer_uid', // ID for the user in client database
    )

### Create tokens from refresh token

    refresh_token = '' # fetched from database
    transaction_tokens = Berbix::Tokens.from_refresh(refresh_token)

### Fetch transaction data

    transaction_data = client.fetch_transaction(transaction_tokens)
 
## Reference

### `Client`

#### Methods

##### `constructor(options)`

Supported options:

 * `client_id` (required) - The client ID that can be found in your Berbix Dashboard.
 * `client_secret` (required) - The client secret that can be found in your Berbix Dashboard.
 * `environment` - Which environment the client uses, defaults to `:production`.
 * `http_client` - An optional override for the default HTTP client.

##### `create_transaction(options): Tokens`

Creates a transaction within Berbix to initialize the client SDK. Typically after creating
a transaction, you will want to store the refresh token in your database associated with the
currently active user session.

Supported options:

 * `email` - Previously verified email address for a user.
 * `phone` - Previously verified phone number for a user.
 * `customer_uid` - An ID or identifier for the user in your system.

##### `fetch_transaction(tokens: Tokens): object`

Fetches all of the information associated with the transaction. If the user has already completed the steps of the transaction, then this will include all of the elements of the transaction payload as described on the (Berbix developer docs)[https://developers.berbix.com].

##### `refresh_tokens(tokens: Tokens): void`

This is typically not needed to be called explicitly as it will be called by the higher-level
SDK methods, but can be used to get fresh client or access tokens.

### `Tokens`

#### Properties

##### `access_token: string`

This is the short-lived bearer token that the backend SDK uses to identify requests associated with a given transaction. This is not typically needed when using the higher-level SDK methods.

##### `client_token: string`

This is the short-lived token that the frontend SDK uses to identify requests associated with a given transaction. After transaction creation, this will typically be sent to a frontend SDK.

##### `refresh_token: string`

This is the long-lived token that allows you to create new tokens after the short-lived tokens have expired. This is typically stored in the database associated with the given user session.

##### `transaction_id: number`

The internal Berbix ID number associated with the transaction.

##### `expiry: Date`

The time at which the access and client tokens will expire.

#### Static methods

##### `from_refresh(refreshToken: string): Tokens`

Creates a tokens object from a refresh token, which can be passed to higher-level SDK methods. The SDK will handle refreshing the tokens for accessing relevant data.
