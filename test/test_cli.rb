# frozen_string_literal: true

require "minitest/autorun"
require "minitest/mock"
require "tmpdir"
require_relative "../lib/opencode_lmstudio/cli"
require_relative "../lib/opencode_lmstudio/client"
require_relative "../lib/opencode_lmstudio/config"

module OpencodeLmstudio
  class TestCLI < Minitest::Test
    def setup
      @tmpdir = Dir.mktmpdir
      @config_path = File.join(@tmpdir, "opencode.jsonc")
    end

    def teardown
      FileUtils.remove_entry(@tmpdir)
    end

    def run_cli(*args)
      out, err = capture_io do
        CLI.new(["-c", @config_path, *args]).run
      end
      [out, err]
    end

    def test_default_host_and_port
      cli = CLI.new(["-c", @config_path])
      assert_equal "192.168.10.2", cli.send(:parse_options)[:host] || CLI::DEFAULT_HOST
      assert_equal "1234", CLI::DEFAULT_PORT
    end

    def test_host_from_option
      cli = CLI.new(["-H", "10.0.0.1", "-c", @config_path])
      options = cli.instance_variable_get(:@options)
      assert_equal "10.0.0.1", options[:host]
    end

    def test_port_from_option
      cli = CLI.new(["-p", "5678", "-c", @config_path])
      options = cli.instance_variable_get(:@options)
      assert_equal "5678", options[:port]
    end

    def test_model_from_option
      cli = CLI.new(["-m", "my-model", "-c", @config_path])
      options = cli.instance_variable_get(:@options)
      assert_equal "my-model", options[:model]
    end

    # rubocop:disable Metrics/MethodLength
    def test_run_updates_config
      stub_fetch = ->(*) { %w[model-a model-b] }
      Client.stub(:new, lambda { |host:, port:|
        obj = Client.allocate
        obj.define_singleton_method(:fetch_models) { stub_fetch.call }
        obj.define_singleton_method(:base_url) { "http://#{host}:#{port}/v1" }
        obj
      }) do
        out, _err = run_cli
        assert_match "Updated", out
        assert_match "model-a", out
        assert_match "model-b", out
      end
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/MethodLength
    def test_run_raises_when_no_models_returned
      Client.stub(:new, lambda { |host:, port:|
        obj = Client.allocate
        obj.define_singleton_method(:fetch_models) { [] }
        obj.define_singleton_method(:base_url) { "http://#{host}:#{port}/v1" }
        obj
      }) do
        _out, err = capture_io do
          assert_raises(SystemExit) { CLI.new(["-c", @config_path]).run }
        end
        assert_match "No models returned", err
      end
    end
    # rubocop:enable Metrics/MethodLength

    def test_run_uses_env_host
      ENV["LMSTUDIO_HOST"] = "1.2.3.4"
      cli = CLI.new(["-c", @config_path])
      host = cli.instance_variable_get(:@options)[:host] || ENV.fetch("LMSTUDIO_HOST", CLI::DEFAULT_HOST)
      assert_equal "1.2.3.4", host
    ensure
      ENV.delete("LMSTUDIO_HOST")
    end

    def test_run_uses_env_port
      ENV["LMSTUDIO_PORT"] = "9999"
      cli = CLI.new(["-c", @config_path])
      port = cli.instance_variable_get(:@options)[:port] || ENV.fetch("LMSTUDIO_PORT", CLI::DEFAULT_PORT)
      assert_equal "9999", port
    ensure
      ENV.delete("LMSTUDIO_PORT")
    end
  end
end
