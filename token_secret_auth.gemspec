# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "token_secret_auth/version"

Gem::Specification.new do |spec|
  spec.name          = "token_secret_auth"
  spec.version       = TokenSecretAuth::VERSION
  spec.authors       = ["tgaff"]
  spec.email         = ["tgaff@alumni.nd.edu"]

  spec.summary       = %q{Simple token+secret authentication gem.}
  spec.description   = %q{Simple token + secret authentication gem with encrypted secrets.}
  spec.homepage      = "https://github.com/tgaff/token_secret_auth"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  # spec.bindir        = "exe"
  # spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  
  spec.add_runtime_dependency "hashids", "~>1.0"
  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.11"
end
