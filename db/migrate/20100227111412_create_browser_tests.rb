class CreateBrowserTests < ActiveRecord::Migration
  def self.up
    create_table :browser_tests do |t|
      t.string :method, :url, :user_agent
      t.boolean :result, :bogus
      
      t.timestamps
    end
  end

  def self.down
    drop_table :browser_tests
  end
end
