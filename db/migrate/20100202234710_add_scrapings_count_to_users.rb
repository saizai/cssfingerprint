class AddScrapingsCountToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :scrapings_count, :integer, :default => 0, :null => false
    
    User.find_each {|user|
      user.update_attribute :scrapings_count, user.scrapings.count
    }
  end

  def self.down
    remove_column :users, :scrapings_count
  end
end
