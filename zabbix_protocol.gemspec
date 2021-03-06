# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zabbix_protocol/version'

Gem::Specification.new do |spec|
  spec.name          = "zabbix_protocol"
  spec.version       = ZabbixProtocol::VERSION
  spec.authors       = ["Genki Sugawara"]
  spec.email         = ["sgwr_dts@yahoo.co.jp"]
  spec.summary       = %q{Zabbix protocols builder/parser.}
  spec.description   = %q{Zabbix protocols builder/parser.}
  spec.homepage      = "https://github.com/winebarrel/zabbix_protocol"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "multi_json"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.0.0"
end
