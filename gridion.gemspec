$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "gridion/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "gridion"
  s.version     = Gridion::VERSION
  s.authors     = ["William Yeung"]
  s.email       = ["william@tofugear.com"]
  s.homepage    = "http://github.com/goodwill/gridion"
  s.summary     = "Simple grid helper for rails"
  s.description = "Simple grid helper for rails"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]



  s.add_development_dependency "sqlite3"
  s.add_development_dependency "kaminari"
end
