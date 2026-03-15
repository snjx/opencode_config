# frozen_string_literal: true

require "optparse"
require_relative "version"
require_relative "client"
require_relative "config"

module OpencodeLmstudio
  # CLI entry point. Parses arguments, fetches models, and updates opencode config.
  class CLI
    DEFAULT_HOST = "192.168.10.2"
    DEFAULT_PORT = "1234"

    def initialize(argv)
      @argv = argv
      @options = parse_options
    end

    def run
      client = build_client
      config = Config.new(@options[:config] || ENV.fetch("OPENCODE_CONFIG", nil))
      fetch_and_update(client, config)
    rescue StandardError => e
      warn "Error: #{e.message}"
      exit 1
    end

    private

    def build_client
      host = @options[:host] || ENV.fetch("LMSTUDIO_HOST", DEFAULT_HOST)
      port = @options[:port] || ENV.fetch("LMSTUDIO_PORT", DEFAULT_PORT)
      Client.new(host: host, port: port.to_s)
    end

    def fetch_and_update(client, config)
      puts "Fetching models from #{client.base_url}..."
      model_ids = client.fetch_models
      raise "No models returned from LM Studio" if model_ids.empty?

      puts "Found #{model_ids.size} model(s)"
      default_model = config.update_models(model_ids, client.base_url, default_model: @options[:model])
      print_result(config.path, client.base_url, default_model, model_ids)
    end

    def print_result(config_path, base_url, default_model, model_ids)
      puts
      puts "Updated #{config_path}"
      puts "  baseURL : #{base_url}"
      puts "  default : #{default_model}"
      puts "  models  :"
      model_ids.each { |id| puts "    - #{id}" }
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength
    def parse_options
      options = {}
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: opencode-lmstudio [options]"
        opts.separator ""
        opts.separator "Options:"

        opts.on("-H", "--host HOST",
                "LM Studio host (env: LMSTUDIO_HOST, default: #{DEFAULT_HOST})") do |v|
          options[:host] = v
        end

        opts.on("-p", "--port PORT",
                "LM Studio port (env: LMSTUDIO_PORT, default: #{DEFAULT_PORT})") do |v|
          options[:port] = v
        end

        opts.on("-c", "--config PATH",
                "Path to opencode.jsonc (env: OPENCODE_CONFIG, default: ~/.config/opencode/opencode.jsonc)") do |v|
          options[:config] = v
        end

        opts.on("-m", "--model MODEL",
                "Set default model (otherwise keeps current setting)") do |v|
          options[:model] = v
        end

        opts.on("-v", "--version", "Print version") do
          puts VERSION
          exit
        end

        opts.on("-h", "--help", "Show this help") do
          puts opts
          exit
        end
      end

      parser.parse!(@argv)
      options
    rescue OptionParser::InvalidOption => e
      warn e.message
      exit 1
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength
  end
end
