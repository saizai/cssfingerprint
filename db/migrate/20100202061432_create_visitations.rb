class CreateVisitations < ActiveRecord::Migration
  def self.up
    create_table :visitations do |t|
      t.integer :scraping_id, :null => false
      t.integer :site_id, :null => false
      t.boolean :visited, :default => nil, :null => false # don't insert unless you know
      
      t.timestamps
    end
    
    add_index :visitations, [:scraping_id, :site_id], :unique => true
    add_index :visitations, :site_id
  end

  def self.down
    drop_table :visitations
  end
end
