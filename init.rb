require 'has_versions'
require File.dirname(__FILE__) + "/lib/version"
ActiveRecord::Base.send(:include, SimplesIdeias::Versions)
