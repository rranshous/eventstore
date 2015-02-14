Gem::Specification.new do |s|
  s.name        = 'eventstore'
  s.version     = '0.0.5'
  s.summary     = "EventStore HTTP client"
  s.description = "EventStore HTTP client for simple reading and writing"
  s.authors     = ["Robby Ranshous"]
  s.email       = 'rranshous@gmail.com'
  s.files       = Dir.glob('lib/**/*')
  s.homepage    = 'http://oneinchmile.com'
  s.add_runtime_dependency 'httparty'
  s.add_runtime_dependency 'cql-rb'
  s.add_runtime_dependency 'feedjira'
  s.add_runtime_dependency 'persistent_httparty'
end
