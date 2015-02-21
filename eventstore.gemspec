Gem::Specification.new do |s|
  s.name        = 'eventstore'
  s.version     = '0.1.4'
  s.summary     = "EventStore HTTP client"
  s.description = "EventStore HTTP client for simple reading and writing"
  s.authors     = ["Robby Ranshous"]
  s.email       = 'rranshous@gmail.com'
  s.files       = Dir.glob('lib/**/*')
  s.homepage    = 'https://github.com/rranshous/eventstore'
  s.licenses    = ['Beerware']
  s.add_runtime_dependency 'httparty', '~> 0.13'
  s.add_runtime_dependency 'cql-rb', '~> 2.0'
  s.add_runtime_dependency 'feedjira', '~> 1.6'
  s.add_runtime_dependency 'persistent_httparty', '~> 0.1'
end
