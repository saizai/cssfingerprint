class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :cookie, :null => false
      
      t.timestamps
    end
    
    add_index :users, :cookie, :unique => true
  end

  def self.down
    drop_table :users
  end
end
