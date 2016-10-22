require File.expand_path('../../spec/spec_helper', File.dirname(__FILE__))

require 'aruba/cucumber'

Before do
  delete_environment_variable 'RUBYOPT'
  delete_environment_variable 'BUNDLE_BIN_PATH'
  delete_environment_variable 'BUNDLE_GEMFILE'
  @aruba_timeout_seconds = 60
end 
