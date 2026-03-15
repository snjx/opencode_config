require_relative "lib/opencode_lmstudio/version"

Gem::Specification.new do |spec|
  spec.name          = "opencode_lmstudio"
  spec.version       = OpencodeLmstudio::VERSION
  spec.authors       = ["shinjinakashima"]
  spec.summary       = "CLI tool to sync LM Studio models into opencode config"
  spec.description   = "Fetches available models from LM Studio and updates opencode.jsonc"
  spec.homepage      = "https://github.com/shinjinakashima/opencode_lmstudio"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0"

  spec.files         = Dir["lib/**/*.rb", "bin/*", "*.gemspec", "LICENSE", "README.md"]
  spec.bindir        = "bin"
  spec.executables   = ["opencode-lmstudio"]
  spec.require_paths = ["lib"]
end
