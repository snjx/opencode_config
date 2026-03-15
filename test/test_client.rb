# frozen_string_literal: true

require "minitest/autorun"
require "minitest/mock"
require "net/http"
require_relative "../lib/opencode_lmstudio/client"

module OpencodeLmstudio
  class TestClient < Minitest::Test
    def setup
      @client = Client.new(host: "192.168.10.2", port: "1234")
    end

    def test_base_url
      assert_equal "http://192.168.10.2:1234/v1", @client.base_url
    end

    # rubocop:disable Metrics/MethodLength
    def test_fetch_models_parses_response
      body = JSON.generate({
                             "object" => "list",
                             "data" => [
                               { "id" => "model-a", "object" => "model" },
                               { "id" => "model-b", "object" => "model" }
                             ]
                           })
      response = Net::HTTPSuccess.new("1.1", "200", "OK")
      response.instance_variable_set(:@body, body)
      response.instance_variable_set(:@read, true)

      Net::HTTP.stub(:get_response, response) do
        assert_equal %w[model-a model-b], @client.fetch_models
      end
    end
    # rubocop:enable Metrics/MethodLength

    def test_fetch_models_raises_on_http_error
      response = Net::HTTPInternalServerError.new("1.1", "500", "Internal Server Error")

      Net::HTTP.stub(:get_response, response) do
        assert_raises(RuntimeError) { @client.fetch_models }
      end
    end

    def test_fetch_models_raises_on_connection_refused
      Net::HTTP.stub(:get_response, ->(_) { raise Errno::ECONNREFUSED }) do
        assert_raises(RuntimeError) { @client.fetch_models }
      end
    end
  end
end
