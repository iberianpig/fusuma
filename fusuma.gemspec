# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fusuma/version"

Gem::Specification.new do |spec|
  spec.name = "fusuma"
  spec.version = Fusuma::VERSION
  spec.authors = ["iberianpig"]
  spec.email = ["yhkyky@gmail.com"]

  spec.summary = "Multitouch gestures with libinput driver, Linux"
  spec.description = "Fusuma is multitouch gesture recognizer. This gem makes your touchpad on Linux able to recognize swipes or pinchs and assign command to them. Read installation on Github(https://github.com/iberianpig/fusuma#installation)."
  spec.homepage = "https://github.com/iberianpig/fusuma"
  spec.license = "MIT"

  spec.files = Dir["{bin,lib,exe}/**/*", "LICENSE*", "README*", "*.gemspec"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.metadata = {
    "rubygems_mfa_required" => "true",
    "yard.run" => "yri" # use "yard" to build full HTML docs.
  }

  spec.required_ruby_version = ">= 2.7"
  # https://packages.ubuntu.com/search?keywords=ruby&searchon=names&exact=1&suite=all&section=main
  # support focal (20.04LTS) 2.7
end
