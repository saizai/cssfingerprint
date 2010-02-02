class CreateScrapings < ActiveRecord::Migration
  def self.up
    create_table :scrapings do |t|
      t.integer :user_id # null allowed, because we need to set up a scraping *before* we can identify its user
      t.integer :visitations_count, :default => 0, :null => false
      
      t.timestamps
    end
    
    add_index :scrapings, :user_id
    add_index :scrapings, :visitations_count
  end

  def self.down
    drop_table :scrapings
  end
end
