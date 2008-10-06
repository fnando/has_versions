has_versions
============

has_versions is a simple plugin to version ActiveRecord objects. The versioned
data is saved using Marshal. You can specify what attributes are going to be
versioned and if versioning is automatically or not.

Installation
------------

1) Install the plugin with `script/plugin install git://github.com/fnando/has_versions.git`

2) Generate a migration with `script/generate migration create_versions` and add the following code:

	class CreateVersions < ActiveRecord::Migration
	  def self.up
	    create_table :versions do |t|
	  	  t.references :versionable, :polymorphic => true
	  	  t.references :user
	  	  t.binary :data
	  	  t.datetime :created_at
	  	  t.integer :version, :default => 0, :null => false
	  	end

	  	add_index :versions, :versionable_type
	  	add_index :versions, :versionable_id
	  	add_index :versions, :user_id
	  	add_index :versions, :version
	  end

	  def self.down
	    drop_table :versions
	  end
	end

3) Add the column `version` to all models you want to be versioned; first create the migration:

	script/generate migration add_version_support_to_posts

Then add the following code:

	class AddVersionSupportToPosts < ActiveRecord::Migration
	  def self.up
	    change_table :posts do |t|
	      t.integer :version, :default => 0, :null => false
	    end
	  end

	  def self.down
	    remove_column :posts, :version
	  end
	end

3) Run the migrations with `rake db:migrate`

Usage
-----

1) Add the association to your User model

	class User < ActiveRecord::Base
	  has_many :versions, :dependent => :nullify
	end

2) Add the method call `has_comments` to your model.

	class Post < ActiveRecord::Base
	  has_versions
	end

	post = Post.first
	user = User.first
	
	# create the version only if any versioned attribute
	# has changed
	post.create_version
	
	# create a version anyway!
	post.create_version!
	
	# retrieve current version number
	post.version
	
	# retrieve current version object
	post.versions.current
	
	# retrieve version #3
	post.versions.get(3)
	
	# retrive version #3 and
	# raise SimplesIdeias::Versions::Exception::VersionNotFound
	# if not found
	
	# revert to a specific version,
	# returning nil if version is not found
	post.versions.revert_to(1)
	
	# revert to a specific version and
	# raise SimplesIdeias::Versions::Exception::VersionNotFound 
	# if version is not found
	post.versions.revert_to!(100)
	
	# save an object without creating a version
	post.save_without_version # => same as post.save
	post.save_without_version(false) # => same as post.save(false)
	post.save_without_version! # => post.save!
	
	# set the user that created the version
	post.version_author = user
	
	# retrieve version author
	post.version_author
	
	# return true if version number >= 1
	post.versioned?
	
	# return true if current saving process
	# is not meant to create a version
	post.save_without_version?
	
	# list of versioned attributes
	post.versioned_attributes	
	
	# you can control weither to create a version or not by
	# overriding the method `create_version?`
	class Post < ActiveRecord::Base
	  has_versions
	
	  def create_version?
	    false
	  end
	end
	
	# other possible options
	has_versions :attributes => :all
	has_versions :attributes => :content
	has_versions :attributes => %w(content excerpt)
	has_versions :auto => false
	has_versions :except => :formatted_content
	
What about displaying a diff from two different versions? Well, you can use
the helper method `diff`.

	<%= diff @newer.data['content'], @newer.data['content'] %>

Use this CSS to display some formatted text:

	.diff ins {
		background: #baffa6;
		text-decoration: none;
	}

	.diff del {
		background: #f88;
		text-decoration: none;
	}

**NOTE**: You should have an User model. **Otherwise, this won't work!**

To-Do
-----

* <del>Create view helpers to display formatted version diffs</del>

Maintainer
----------

* Nando Vieira ([http://simplesideias.com.br](http://simplesideias.com.br))

License
-------

(The MIT License)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.