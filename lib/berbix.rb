require 'net/https'
require 'json'

module Berbix
  SDK_VERSION = '0.0.11'
  CLOCK_DRIFT = 300

  class HTTPClient
    def request(method, url, headers, opts={})
      raise 'subclass must implement request'
    end
  end

  class NetHTTPClient < HTTPClient
    attr_reader :read_timeout
    attr_reader :open_timeout

    def initialize(opts={})
      # Sets the defaults to align with the Net::HTTP defaults
      @open_timeout = opts[:open_timeout] || 60
      @read_timeout = opts[:read_timeout] || 60
    end

    def request(method, url, headers, opts={})
      uri = URI(url)
      klass = if method == :post
        Net::HTTP::Post
      elsif method == :patch
        Net::HTTP::Patch
      elsif method == :delete
        Net::HTTP::Delete
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
        http.read_timeout = read_timeout
        http.open_timeout = open_timeout
      end
      res = cli.request(req)
      code = res.code.to_i
      if code < 200 || code >= 300
        raise(Berbix::BerbixError, 'unexpected status code returned')
      end
      if code == 204
        return
      end
      JSON.parse(res.body)
    end
  end

  class Tokens
    attr_reader :access_token, :client_token, :refresh_token, :expiry, :transaction_id, :user_id, :response

    def initialize(refresh_token, access_token=nil, client_token=nil, expiry=nil, transaction_id=nil, response=nil)
      @refresh_token = refresh_token
      @access_token = access_token
      @client_token = client_token
      @expiry = expiry
      @transaction_id = transaction_id
      @response = response
    end

    def refresh!(access_token, client_token, expiry, transaction_id)
      @access_token = access_token
      @client_token = client_token
      @expiry = expiry
      @transaction_id = transaction_id
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
      @api_secret = opts[:api_secret] || opts[:client_secret]
      @api_host = api_host(opts)
      @http_client = opts[:http_client] || NetHTTPClient.new

      if @api_secret.nil?
        raise ':api_secret must be provided when instantiating Berbix client'
      end
    end

    def create_transaction(opts={})
      payload = {}
      payload[:email] = opts[:email] unless opts[:email].nil?
      payload[:phone] = opts[:phone] unless opts[:phone].nil?
      payload[:customer_uid] = opts[:customer_uid].to_s unless opts[:customer_uid].nil?
      payload[:template_key] = opts[:template_key] unless opts[:template_key].nil?
      payload[:hosted_options] = opts[:hosted_options] unless opts[:hosted_options].nil?
      fetch_tokens('/v0/transactions', payload)
    end

    def refresh_tokens(tokens)
      fetch_tokens('/v0/tokens', {
        'refresh_token' => tokens.refresh_token,
        'grant_type' => 'refresh_token',
      })
    end

    def fetch_transaction(tokens)
      token_auth_request(:get, tokens, '/v0/transactions')
    end

    def delete_transaction(tokens)
      token_auth_request(:delete, tokens, '/v0/transactions')
    end

    def update_transaction(tokens, opts={})
      payload = {}
      payload[:action] = opts[:action] unless opts[:action].nil?
      payload[:note] = opts[:note] unless opts[:note].nil?
      token_auth_request(:patch, tokens, '/v0/transactions', data: payload)
    end

    def override_transaction(tokens, opts={})
      payload = {}
      payload[:response_payload] = opts[:response_payload] unless opts[:response_payload].nil?
      payload[:flags] = opts[:flags] unless opts[:flags].nil?
      payload[:override_fields] = opts[:override_fields] unless opts[:override_fields].nil?
      token_auth_request(:patch, tokens, '/v0/transactions/override', data: payload)
    end

    def create_continuation(tokens)
      result = token_auth_request(:post, tokens, '/v0/continuations')
      result['value']
    end

    def validate_signature(secret, body, header)
      parts = header.split(',')
      # Version (parts[0]) is currently unused
      timestamp = parts[1]
      signature = parts[2]
      if timestamp.to_i < Time.now.to_i - CLOCK_DRIFT
        return false
      end
      digest = OpenSSL::Digest::SHA256.new
      hmac = OpenSSL::HMAC.new(secret, digest)
      hmac << timestamp
      hmac << ','
      hmac << secret
      hmac << ','
      hmac << body
      hmac.hexdigest == signature
    end

    private

    def refresh_if_necessary!(tokens)
      if tokens.needs_refresh?
        refreshed = refresh_tokens(tokens)
        tokens.refresh!(refreshed.access_token, refreshed.client_token, refreshed.expiry, refreshed.transaction_id)
      end
    end

    def token_auth_request(method, tokens, path, opts={})
      refresh_if_necessary!(tokens)
      headers = {
        'Authorization' => 'Bearer ' + tokens.access_token,
        'Content-Type' => 'application/json',
        'User-Agent' => 'BerbixRuby/' + SDK_VERSION,
      }
      @http_client.request(method, @api_host + path, headers, opts)
    end

    def fetch_tokens(path, payload)
      headers = {
        'Content-Type' => 'application/json',
        'User-Agent' => 'BerbixRuby/' + SDK_VERSION,
      }
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
        result['transaction_id'],
        result)
    end

    def auth
      { user: @api_secret, pass: '' }
    end

    def api_host(opts)
      if !opts[:api_host].nil?
        return opts[:api_host]
      else
        return 'https://api.berbix.com'
      end
    end
    
  end

  class BerbixError < StandardError
  end
end
