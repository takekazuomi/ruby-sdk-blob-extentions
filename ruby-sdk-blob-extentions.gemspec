# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "azure_blob_extentions"
  spec.version       = "0.0.2"
  spec.authors       = ["Takekazu Omi"]
  spec.email         = ["takekazuomi@gmail.com"]
  spec.description   = %q{Extentions for windows azure sdk for ruby 0.5.0}
  spec.summary       = %q{blob.exists and parallel upload}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "azure"
  spec.add_runtime_dependency "parallel"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
