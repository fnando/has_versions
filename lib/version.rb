class Version < ActiveRecord::Base
  belongs_to :versionable, :polymorphic => true
  belongs_to :user
  
  before_save :increment_version_number
  
  def data=(options)
    raise ArgumentError, "expected Hash; got #{options.class}" unless options.kind_of?(Hash)
    write_attribute(:data, Marshal.dump(options))
  end
  
  def data
    unless read_attribute(:data).blank?
      Marshal.load(read_attribute(:data))
    else
      {}
    end
  end
  
  private
    def increment_version_number
      write_attribute :version, versionable.versions.count + 1
    end
end