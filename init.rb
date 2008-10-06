require 'has_versions'
require File.dirname(__FILE__) + "/lib/version"
require File.dirname(__FILE__) + "/lib/html_diff"
ActiveRecord::Base.send(:include, SimplesIdeias::Versions::ActiveRecord)
ActionView::Base.send(:include, SimplesIdeias::Versions::ActionView)
