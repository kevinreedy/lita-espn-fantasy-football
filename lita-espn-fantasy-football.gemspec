Gem::Specification.new do |s|
  s.name          = "lita-espn-fantasy-football"
  s.version       = "0.1.6"
  s.authors       = ["Kevin Reedy", "Miles Evenson"]
  s.email         = ["kevinreedy@gmail.com", "miles.evenson@gmail.com"]
  s.description   = "Lita handler for ESPN Fantasy Football"
  s.summary       = "Lita handler for ESPN Fantasy Football"
  s.homepage      = "https://github.com/kevinreedy/lita-espn-fantasy-football"
  s.license       = "Apache License, v2.0"
  s.metadata      = { "lita_plugin_type" => "handler" }

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_runtime_dependency "lita", ">= 4.6"
  s.add_runtime_dependency "nokogiri", ">= 1.6"
  s.add_runtime_dependency "terminal-table", ">= 1.5"

  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "pry-byebug"
  s.add_development_dependency "rake"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "rspec", ">= 3.0.0"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "lita-console"
end
