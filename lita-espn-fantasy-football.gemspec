Gem::Specification.new do |spec|
  spec.name          = "lita-espn-fantasy-football"
  spec.version       = "0.1.0"
  spec.authors       = ["Kevin Reedy", "Miles Evenson"]
  spec.email         = ["kevinreedy@gmail.com", "miles.evenson@gmail.com"]
  spec.description   = "Lita handler for ESPN Fantasy Football"
  spec.summary       = "Lita handler for ESPN Fantasy Football"
  spec.homepage      = "https://github.com/kevinreedy/lita-espn-fantasy-football"
  spec.license       = "Apache License, v2.0"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.6"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
end
