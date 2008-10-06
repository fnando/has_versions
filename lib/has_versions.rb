module SimplesIdeias
  module Versions
    module ActionView
      def diff(original, changed)
        content_tag :div, HTMLDiff.diff(original, changed), :class => 'diff'
      end
    end
    
    module ActiveRecord
      def self.included(base)
        base.extend ClassMethods
      
        class << base
          attr_accessor :has_versions_options
        end
      end
    
      module Extend
        def current
          proxy_owner.versions.first(:order => 'version desc')
        end
      
        def revert_to(revision)
          object = get(revision)
          return nil unless object
        
          object.data.each {|attr, value| proxy_owner.send("#{attr}=", value) }
        
          proxy_owner.create_version!
          proxy_owner.save_without_version
          current
        end
      
        def revert_to!(revision)
          object = revert_to(revision)
          raise SimplesIdeias::Versions::ActiveRecord::Exception::VersionNotFound unless object
          object
        end
      
        def get(revision)
          proxy_owner.versions.first(:conditions => {:version => revision})
        end
      end
    
      module ClassMethods
        def has_versions(options={})
          include SimplesIdeias::Versions::ActiveRecord::InstanceMethods
        
          self.has_versions_options = {
            :attributes => :all,
            :auto => true,
            :except => []
          }.merge(options)
        
          has_many :versions,
            :as => :versionable, 
            :dependent => :destroy, 
            :extend => SimplesIdeias::Versions::ActiveRecord::Extend
        
          after_save :create_version, :unless => :save_without_version?
        end
      end
    
      module InstanceMethods
        def create_version?
          self.class.has_versions_options[:auto] && 
          versioned_attributes.collect {|attr| send("#{attr}_changed?") }.any? &&
          !@save_without_version
        end
      
        def versioned_attributes
          if self.class.has_versions_options[:attributes] == :all
            attrs = attributes.keys
          else
            attrs = self.class.has_versions_options[:attributes]
          end
        
          except = [self.class.has_versions_options[:except]].flatten.map(&:to_s)
          [attrs].flatten.map(&:to_s) - [self.class.primary_key, except].flatten
        end
      
        def versioned?
          version.to_i > 0
        end
      
        def create_version
          return nil unless create_version?
          create_version!
        end
      
        def create_version!
          returning self.versions.build do |v|
            v.user    = @version_author
            v.data    = versioned_attributes.inject({}) {|attrs, name| attrs[name] = send(name); attrs }
            v.save!

            self.version = v.version
            self.connection.execute(%(UPDATE #{self.class.table_name} SET version = #{v.version} WHERE id = #{self.id}))
            v
          end
        end
      
        def version_author=(user)
          @version_author = user
        end
      
        def version_author
          @version_author ||= versions.current.author
        end
      
        def save_without_version?
          !!@save_without_version
        end
      
        def save_without_version(validate=true)
          @save_without_version = true
          saved = save(validate)
          @save_without_version = true
          saved
        end
      
        def save_without_version!
          @save_without_version = true
          save!
          @save_without_version = true
          nil
        end
      end
    
      module Exception
        class VersionNotFound < StandardError; end
      end
    end
  end
end