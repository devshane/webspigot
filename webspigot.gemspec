Gem::Specification.new do |gem|
  gem.authors = ['Shane Thomas']
  gem.email = ['shane@devshane.com']
  gem.homepage = 'https://github.com/devshane/webspigot'

  gem.summary = 'A thing.'
  gem.description = 'A thing.'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = ['webspigot']
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})

  gem.name = 'webspigot'
  gem.version = '0.0.1'
  gem.date = '2014-02-14'
  gem.licenses = ['MIT']

  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 1.9.3'

  gem.add_runtime_dependency 'rake', '~> 10.1', '>= 10.1.1'
  gem.add_runtime_dependency 'rspec', '~> 2.14', '>= 2.14.1'
  gem.add_runtime_dependency 'mechanize', '~> 2.7', '>= 2.7.3'
end
