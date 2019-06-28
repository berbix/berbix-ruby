require 'net/https'
require 'json'

module Berbix

  class HTTPClient
    def request(method, url, headers, opts={})
      raise 'subclass must implement request'
    end
  end

  class NetHTTPClient < HTTPClient
    def request(method, url, headers, opts={})
      uri = URI(url)
      klass = if method == :post
        Net::HTTP::Post
      else
        Net::HTTP::Get
      end
      req = klass.new(uri.to_s, headers)
      unless opts[:data].nil?
        req.body = opts[:data].to_json
      end
      unless opts[:auth].nil?
        req.basic_auth(opts[:auth][:user], opts[:auth][:pass])
      end
      cli = Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = true
      end
      res = cli.request(req)
      code = res.code.to_i
      if code < 200 || code >= 300
        raise 'unexpected status code returned'
      end
      JSON.parse(res.body)
    end
  end

  class Tokens
    attr_reader :access_token, :client_token, :refresh_token, :expiry, :transaction_id, :user_id

    def initialize(refresh_token, access_token=nil, client_token=nil, expiry=nil, transaction_id=nil)
      @refresh_token = refresh_token
      @access_token = access_token
      @client_token = client_token
      @expiry = expiry
      @transaction_id = transaction_id
      @user_id = transaction_id
    end

    def refresh!(access_token, client_token, expiry, transaction_id)
      @access_token = access_token
      @client_token = client_token
      @expiry = expiry
      @transaction_id = transaction_id
      @user_id = transaction_id
    end

    def needs_refresh?
      @access_token.nil? || @expiry.nil? || @expiry < Time.now
    end

    def self.from_refresh(refresh_token)
      Tokens.new(refresh_token)
    end
  end

  class Client
    def initialize(opts={})
      @client_id = opts[:client_id]
      @client_secret = opts[:client_secret]
      @api_host = api_host(opts)
      @http_client = opts[:http_client] || NetHTTPClient.new

      if @client_id.nil?
        raise ':client_id must be provided when instantiating Berbix client'
      end
      if @client_secret.nil?
        raise ':client_secret must be provided when instantiating Berbix client'
      end
    end

    def create_transaction(opts={})
      payload = {}
      payload[:email] = opts[:email] unless opts[:email].nil?
      payload[:phone] = opts[:phone] unless opts[:phone].nil?
      payload[:customer_uid] = opts[:customer_uid] unless opts[:customer_uid].nil?
      fetch_tokens('/v0/transactions', payload)
    end

    # This method is deprecated, please use create_transaction instead
    def create_user(opts={})
      create_transaction(opts)
    end

    def refresh_tokens(tokens)
      fetch_tokens('/v0/tokens', {
        'refresh_token' => tokens.refresh_token,
        'grant_type' => 'refresh_token',
      })
    end

    def exchange_code(code)
      fetch_tokens('/v0/tokens', {
        'code' => code,
        'grant_type' => 'authorization_code',
      })
    end

    def fetch_transaction(tokens)
      token_auth_request(:get, tokens, '/v0/transactions')
    end

    # This method is deprecated, please use fetch_transaction instead
    def fetch_user(tokens)
      fetch_transaction(tokens)
    end

    def create_continuation(tokens)
      result = token_auth_request(:post, tokens, '/v0/continuations')
      result['value']
    end

    private

    def refresh_if_necessary!(tokens)
      if tokens.needs_refresh?
        refreshed = refresh_tokens(tokens)
        tokens.refresh!(refreshed.access_token, refreshed.client_token, refreshed.expiry, refreshed.transaction_id)
      end
    end

    def token_auth_request(method, tokens, path)
      refresh_if_necessary!(tokens)
      headers = {
        'Authorization' => 'Bearer ' + tokens.access_token,
        'Content-Type' => 'application/json',
      }
      @http_client.request(method, @api_host + path, headers)
    end

    def fetch_tokens(path, payload)
      headers = { 'Content-Type' => 'application/json' }
      result = @http_client.request(
        :post,
        @api_host + path,
        headers,
        data: payload,
        auth: auth())
      Tokens.new(
        result['refresh_token'],
        result['access_token'],
        result['client_token'],
        Time.now + result['expires_in'],
        result['transaction_id'])
    end

    def auth
      { user: @client_id, pass: @client_secret }
    end

    def api_host(opts)
      unless opts[:api_host].nil?
        return opts[:api_host]
      end

      opts[:environment] ||= :production
      case opts[:environment]
      when :production
        return 'https://api.berbix.com'
      when :staging
        return 'https://api.staging.berbix.com'
      when :sandbox
        return 'https://api.sandbox.berbix.com'
      else
        raise 'invalid environment value specified';
      end
    end
  end

end
