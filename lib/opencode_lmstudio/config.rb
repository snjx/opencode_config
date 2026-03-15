# frozen_string_literal: true

require "json"
require "fileutils"

module OpencodeLmstudio
  # Reads and writes opencode.jsonc, including JSONC comment stripping.
  class Config
    DEFAULT_CONFIG_PATH = File.expand_path("~/.config/opencode/opencode.jsonc")

    def initialize(path = nil)
      @path = path || ENV.fetch("OPENCODE_CONFIG", DEFAULT_CONFIG_PATH)
    end

    attr_reader :path

    # Updates provider.lmstudio.models with all given model IDs and returns the model set as default.
    def update_models(model_ids, base_url, default_model: nil)
      config = read
      model = default_model ? resolve_model(model_ids, default_model) : (config["model"] || model_ids.first)
      config["model"] = model
      config["provider"] ||= {}
      config["provider"]["lmstudio"] = build_lmstudio_section(model_ids, base_url, config["provider"]["lmstudio"])
      write(config)
      model
    end

    private

    def resolve_model(model_ids, preferred)
      if preferred && model_ids.include?(preferred)
        preferred
      else
        warn "Warning: model '#{preferred}' not found, falling back to '#{model_ids.first}'" if preferred
        model_ids.first
      end
    end

    def build_lmstudio_section(model_ids, base_url, existing = nil)
      existing ||= {}
      models = model_ids.each_with_object({}) { |id, h| h[id] = { "name" => id } }
      existing_options = existing["options"] || {}
      existing.merge(
        "name" => existing["name"] || "LM Studio",
        "npm" => existing["npm"] || "@ai-sdk/openai-compatible",
        "models" => models,
        "options" => existing_options.merge("baseURL" => base_url)
      )
    end

    def read
      return { "$schema" => "https://opencode.ai/config.json" } unless File.exist?(@path)

      JSON.parse(strip_jsonc_comments(File.read(@path)))
    end

    def write(data)
      FileUtils.mkdir_p(File.dirname(@path))
      File.write(@path, "#{JSON.pretty_generate(data)}\n")
    end

    def strip_jsonc_comments(content)
      content = content.gsub(%r{/\*.*?\*/}m, "")
      content.lines.map { |line| strip_line_comment(line) }.join
    end

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def strip_line_comment(line)
      result = +""
      in_string = false
      escape_next = false
      i = 0
      while i < line.length
        c = line[i]
        if escape_next
          result << c
          escape_next = false
        elsif c == "\\"
          result << c
          escape_next = true if in_string
        elsif c == '"'
          result << c
          in_string = !in_string
        elsif !in_string && c == "/" && line[i + 1] == "/"
          break
        else
          result << c
        end
        i += 1
      end
      result
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  end
end
