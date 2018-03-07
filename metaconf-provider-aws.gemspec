Gem::Specification.new do |s|
  s.name = 'metaconf-provider-aws'
  s.version     = '0.0.1'
  s.date        = '2018-03-07'
  s.summary     = 'AWS provider for Metaconf.'
  s.description = 'AWS provider for Metaconf.'
  s.authors     = ['Ameir Abdeldayem']
  s.email       = 'ameirh@gmail.com'
  s.files       = Dir['lib/**/*.rb', 'lib/**/*.yaml']
  s.add_runtime_dependency 'aws-sdk', '~> 3'
  s.license = 'MIT'
end
