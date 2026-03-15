# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module OpencodeLmstudio
  # HTTP client for the LM Studio OpenAI-compatible API.
  class Client
    def initialize(host:, port:)
      @host = host
      @port = port
    end

    def base_url
      "http://#{@host}:#{@port}/v1"
    end

    def fetch_models
      uri = URI("#{base_url}/models")
      response = Net::HTTP.get_response(uri)
      raise "HTTP error: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      data["data"].map { |m| m["id"] }
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
      raise "Cannot connect to LM Studio at #{@host}:#{@port} - #{e.message}"
    end
  end
end
