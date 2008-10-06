require "spec_helper"

# unset models used for testing purposes
Object.unset_class('Post', 'User')

class User < ActiveRecord::Base
  has_many :versions, :dependent => :nullify
end

class Post < ActiveRecord::Base
  has_versions :attributes => :all
end

describe "has_versions" do
  before(:each) do
    @attrs = {
      :title => 'What about it?',
      :content => 'Lorem ipsum dolor sit amet, consectetur adipisicing elit...',
      :excerpt => 'Lorem ipsum dolor sit amet, consectetur adipisicing elit...'
    }
    
    @post = Post.create(@attrs)
    @user = User.create(:login => 'johndoe')
  end
  
  after(:each) do
    Post.has_versions_options = {
      :attributes => :all,
      :auto => true,
      :except => []
    }
  end
  
  it "should set class method" do
    Post.should respond_to(:has_versions)
    Post.should respond_to(:has_versions_options)
  end
  
  it "should not be versioned" do
    post = Post.new
    post.should_not be_versioned
  end
  
  it "should be marked as 'to be versioned'" do
    @post.title = 'Updated post'
    @post.create_version?.should be_true
  end
  
  it "should create version" do
    doing {
      @post.title = 'Updated post'
      @post.save!
    }.should change(Version, :count)
  end
  
  it "should increment version" do
    post = Post.new(@attrs)
    post.save!
    post.version.should == 1
    post.versions.current.version.should == 1
    
    post.title = 'Updated post'
    post.save!
    post.version.should == 2
    post.versions.current.version.should == 2
  end
  
  it "should map :all" do
    @post.versioned_attributes.should == (@post.attributes.keys - ["id"])
  end
  
  it "should version only comment and excerpt attributes" do
    Post.has_versions_options[:attributes] = %w(content excerpt)
    @post.versioned_attributes.should == %w(content excerpt)
  end
  
  it "should respect overwritten create_version? method" do
    @post.should_receive(:create_version?).and_return(false)
    
    doing {
      @post.title = 'Updated title'
      @post.save!
    }.should_not change(Version, :count)
  end
  
  it "should bypass create_version? verification" do
    @post.should_not_receive(:create_version?)
    
    doing {
      @post.create_version!
    }.should change(Version, :count)
  end
  
  it "should not create version" do
    @post.should_receive(:create_version?).and_return(false)
    
    doing {
      @post.create_version
    }.should_not change(Version, :count)
  end
  
  it "should Marshal data attribute" do
    attrs = {'title' => 'All about Rails'}
    
    Marshal.should_receive(:dump).with(attrs).and_return('title')
    Marshal.should_receive(:load).with('title').and_return(attrs)
    
    version = Version.new
    version.data = attrs
    version.data
  end
  
  it "should raise if data is not a Hash" do
    doing {
      version = Version.new
      version.data = 'invalid'
    }.should raise_error(ArgumentError)
  end
  
  it "should not automatically create a new version" do
    Post.has_versions_options[:auto] = false
    
    doing {
      @post.title = 'Updated post'
      @post.save!
    }.should_not change(Version, :count)
  end
  
  it "should return current revision" do
    @post.title = 'Updated post'
    @post.save!
    @post.versions.count.should == 2
  end
  
  it "should version all attributes but excerpt" do
    Post.has_versions_options[:except] = :excerpt
    post = Post.new(@attrs)
    post.versioned_attributes.should == (post.attributes.keys - ['id', 'excerpt'])
    
    Post.has_versions_options[:except] = [:excerpt]
    post = Post.new(@attrs)
    post.versioned_attributes.should == (post.attributes.keys - ['id', 'excerpt'])
  end
  
  it "should set author" do
    @post.version_author = @user
    @post.create_version!
    @post.versions.current.user.should == @user
  end
  
  it "should return current revision" do
    @post.versions.current.should == @post.versions.last(:order => 'id desc', :limit => 1)
  end
  
  it "should revert to first revision" do
    @post.title = 'Updated post'
    @post.save!

    doing {
      version_object = @post.versions.revert_to(1)
      version_object.should == @post.versions.current
      version_object.version.should == 3
    }.should change(Version, :count).by(1)

    @post.reload
    @post.version.should == 3
    @post.title.should == 'What about it?'
  end
  
  it "should be nil when trying to revert to a non-existing version" do
    @post.versions.revert_to(-1).should be_nil
  end
  
  it "should raise when trying to revert to a non-existing version" do
    doing {
      @post.versions.revert_to!(-1)
    }.should raise_error(SimplesIdeias::Versions::Exception::VersionNotFound)
  end
  
  it "should be nil when trying to get a non-existing version" do
    @post.versions.get(-1).should be_nil
  end
  
  it "should raise when trying to get to a non-existing version" do
    doing {
      @post.versions.get!(-1)
    }.should raise_error(SimplesIdeias::Versions::Exception::VersionNotFound)
  end
  
  it "should not create version when saving without versioning" do
    doing {
      @post.title = 'Updated post'
      @post.save_without_version.should be_true
      
      @post.title = 'Updated post (again)'
      @post.save_without_version!
    }.should_not change(Version, :count)
  end
  
  it "should skip validation" do
    @post.should_receive(:save).with(false)
    @post.save_without_version(false)
  end
  
  it "should save!" do
    @post.should_receive(:save!)
    @post.save_without_version!
  end
  
  it "should nullify deleted users" do
    @post.title = 'Updated post'
    @post.version_author = @user
    @post.save
    
    @post.versions.current.user.should == @user
    @user.destroy
    @post.versions.current.user.should be_nil
  end
  
  it "should add diff helper" do
    helper = ActionView::Base.new
    helper.diff('displaying the authr name', 'displaying the author name').should have_tag('div.diff') do
      with_tag 'del', 'authr'
      with_tag 'ins', 'author'
    end
  end
end