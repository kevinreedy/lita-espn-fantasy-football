Gem::Specification.new do |s|
  s.name          = 'lita-espn-fantasy-football'
  s.version       = '0.3.2'
  s.authors       = ['Kevin Reedy', 'Miles Evenson']
  s.email         = ['kevinreedy@gmail.com', 'miles.evenson@gmail.com']
  s.description   = 'Lita handler for ESPN Fantasy Football'
  s.summary       = <<-EOF
    This Lita handler is used to scrape data from ESPN's Fantasy Football Site.
    Right now, it is very limited, so PRs are very welcome!
  EOF
  s.homepage      = 'https://github.com/kevinreedy/lita-espn-fantasy-football'
  s.license       = 'Apache-2.0'
  s.metadata      = { 'lita_plugin_type' => 'handler' }

  s.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_runtime_dependency 'lita', '~> 4.7'
  s.add_runtime_dependency 'nokogiri', '~> 1.8'
  s.add_runtime_dependency 'terminal-table', '~> 1.8'

  s.add_development_dependency 'bundler', '~> 1.14'
  s.add_development_dependency 'pry-byebug', '~> 3.5'
  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'rack-test', '~> 0.7'
  s.add_development_dependency 'rspec', '~> 3.6'
  s.add_development_dependency 'simplecov', '~> 0.9'
  s.add_development_dependency 'coveralls', '~> 0.8'
  s.add_development_dependency 'lita-console', '~> 0.0'
  s.add_development_dependency 'rubocop', '~> 0.49'
end
