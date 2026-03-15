# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "json"
require_relative "../lib/opencode_lmstudio/config"

module OpencodeLmstudio
  class TestConfig < Minitest::Test
    def setup
      @tmpdir = Dir.mktmpdir
      @path = File.join(@tmpdir, "opencode.jsonc")
      @config = Config.new(@path)
    end

    def teardown
      FileUtils.remove_entry(@tmpdir)
    end

    def test_update_models_writes_all_models
      @config.update_models(%w[model-a model-b], "http://localhost:1234/v1")

      data = JSON.parse(File.read(@path))
      assert_equal %w[model-a model-b], data["provider"]["lmstudio"]["models"].keys
    end

    def test_update_models_sets_base_url
      @config.update_models(["model-a"], "http://10.0.0.1:5678/v1")

      data = JSON.parse(File.read(@path))
      assert_equal "http://10.0.0.1:5678/v1", data["provider"]["lmstudio"]["options"]["baseURL"]
    end

    def test_update_models_returns_default_model
      result = @config.update_models(%w[model-a model-b], "http://localhost:1234/v1")
      assert_equal "model-a", result
    end

    def test_update_models_respects_explicit_default_model
      result = @config.update_models(%w[model-a model-b], "http://localhost:1234/v1", default_model: "model-b")
      assert_equal "model-b", result
    end

    def test_update_models_preserves_existing_model_if_no_default_given
      File.write(@path, JSON.generate({ "model" => "model-b" }))
      result = @config.update_models(%w[model-a model-b], "http://localhost:1234/v1")
      assert_equal "model-b", result
    end

    def test_update_models_creates_file_if_not_exists
      refute File.exist?(@path)
      @config.update_models(["model-a"], "http://localhost:1234/v1")
      assert File.exist?(@path)
    end

    def test_jsonc_line_comments_are_stripped
      File.write(@path, <<~JSONC)
        {
          // this is a comment
          "model": "model-a"
        }
      JSONC
      @config.update_models(["model-a"], "http://localhost:1234/v1")
      assert File.exist?(@path)
    end

    def test_jsonc_block_comments_are_stripped
      File.write(@path, <<~JSONC)
        {
          /* block comment */
          "model": "model-a"
        }
      JSONC
      @config.update_models(["model-a"], "http://localhost:1234/v1")
      assert File.exist?(@path)
    end

    def test_update_models_falls_back_when_model_not_in_list
      File.write(@path, JSON.generate({ "model" => "old-model" }))
      _out, err = capture_io do
        result = @config.update_models(%w[model-a model-b], "http://localhost:1234/v1")
        assert_equal "model-a", result
      end
      assert_match "old-model", err
    end

    def test_update_models_explicit_model_not_in_list_falls_back
      _out, err = capture_io do
        result = @config.update_models(%w[model-a model-b], "http://localhost:1234/v1", default_model: "missing")
        assert_equal "model-a", result
      end
      assert_match "missing", err
    end

    # rubocop:disable Metrics/MethodLength
    def test_update_models_preserves_extra_lmstudio_keys
      existing = {
        "provider" => {
          "lmstudio" => {
            "name" => "LM Studio",
            "npm" => "@ai-sdk/openai-compatible",
            "apiKey" => "secret",
            "options" => { "baseURL" => "http://old:1234/v1", "timeout" => 30 }
          }
        }
      }
      File.write(@path, JSON.generate(existing))
      @config.update_models(["model-a"], "http://new:1234/v1")
      data = JSON.parse(File.read(@path))
      lmstudio = data["provider"]["lmstudio"]
      assert_equal "secret", lmstudio["apiKey"]
      assert_equal 30, lmstudio["options"]["timeout"]
      assert_equal "http://new:1234/v1", lmstudio["options"]["baseURL"]
    end
    # rubocop:enable Metrics/MethodLength

    def test_jsonc_url_in_string_is_not_stripped_as_comment
      # "http://..." contains "//" but must not be treated as a comment
      File.write(@path, JSON.generate({ "model" => "http://example.com" }))
      @config.update_models(["model-a"], "http://localhost:1234/v1")
      data = JSON.parse(File.read(@path))
      assert_equal "http://localhost:1234/v1", data["provider"]["lmstudio"]["options"]["baseURL"]
    end
  end
end
