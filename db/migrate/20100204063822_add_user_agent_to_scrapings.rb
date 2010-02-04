class AddUserAgentToScrapings < ActiveRecord::Migration
  def self.up
    add_column :scrapings, :user_agent, :string
  end

  def self.down
    remove_column :scrapings, :user_agent, :string
  end
end
