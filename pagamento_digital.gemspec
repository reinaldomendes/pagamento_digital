# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pagamento_digital/version"

Gem::Specification.new do |s|
  s.name        = "pagamento_digital"
  s.version     = PagamentoDigital::Version::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nando Vieira"]
  s.email       = ["fnando.vieira@gmail.com"]
#  s.homepage    = "http://rubygems.org/gems/pagseguro"
#  s.summary     = "The official PagSeguro library"
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rails"        , "~> 3.1"
  s.add_development_dependency "rake"         , "~> 0.9"




end
