class CreateFeeds < ActiveRecord::Migration
  def self.up
    create_table :feeds do |t|
      t.string :url, :name
      t.datetime :last_checked
      t.integer :bloglines_rank
      t.references :site
      
      t.timestamps
    end
    
    add_index :feeds, :url, :unique => true
    add_index :feeds, :site_id
  end

  def self.down
    drop_table :feeds
  end
end
