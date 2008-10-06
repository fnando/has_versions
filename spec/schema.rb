ActiveRecord::Schema.define(:version => 0) do
  create_table :users do |t|
    t.string :login
  end
  
  create_table :posts do |t|
    t.string  :title
    t.text    :content, :excerpt
    t.integer :version, :default => 0, :null => false
    t.timestamps
  end
  
  create_table :versions do |t|
    t.references :versionable, :polymorphic => true
    t.references :user
    t.binary :data
    t.datetime :created_at
    t.integer :version, :default => 0, :null => false
  end
end